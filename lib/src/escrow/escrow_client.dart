/// Client for Stronghold's 60B SHx / 5-year escrow Soroban contract.
///
/// API confirmed against stellar_flutter_sdk v3.3.0 documentation
/// (Soneso/stellar_flutter_sdk, documentation/soroban.md): high-level
/// contract calls go through SorobanClient + ContractSpec-based
/// argument conversion; direct storage reads go through
/// SorobanServer.getContractData.
///
/// Contract spec (verified via `stellar contract inspect` against
/// Mainnet, contract
/// CCA5HAZCPEYXD7JBKAJCVUZUXAK7V5ZFU3QMJO33OJH2OHL3OGLS2P7M):
///   fn lock(account: Address, amount: i128, claim_after: u64)
///     -> Result<(), Error>
///   fn unlock(account: Address) -> Result<(), Error>
///   fn extend_ttl(ttl: u32) -> Result<(), Error>
///   enum DataKey { Token(), MaxLockupDuration(), Escrows(),
///     Escrow(Address) }
///
/// The contract exposes no explicit read/getter function; escrow
/// lookups read contract storage directly via DataKey::Escrow(Address).
library;

import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';
import 'package:stronghold_flutter_sdk/src/core/stronghold_exception.dart';
import 'package:stronghold_flutter_sdk/src/core/stronghold_network.dart';
import 'package:stronghold_flutter_sdk/src/escrow/escrow_models.dart';

// ---- Escrow Client ----

/// Client for reading and writing escrow entries on Stronghold's 60B
/// SHx escrow contract.
class ShxEscrowClient {
  /// Creates a [ShxEscrowClient] for [contractId] (defaults to the
  /// verified Stronghold escrow contract).
  ShxEscrowClient({
    required this.sourceAccountKeyPair,
    required this.network,
    required this.rpcUrl,
    this.contractId = StrongholdConstants.shxEscrowContractId,
  }) : _sorobanServer = SorobanServer(rpcUrl);

  /// The account signing and submitting escrow transactions.
  final KeyPair sourceAccountKeyPair;

  /// The Stellar network to operate against.
  final Network network;

  /// The Soroban RPC URL to use.
  final String rpcUrl;

  /// The escrow contract ID.
  final String contractId;

  final SorobanServer _sorobanServer;

  SorobanClient? _client;

  Future<SorobanClient> _getClient() async {
    return _client ??= await SorobanClient.forClientOptions(
      options: ClientOptions(
        sourceAccountKeyPair: sourceAccountKeyPair,
        contractId: contractId,
        network: network,
        rpcUrl: rpcUrl,
      ),
    );
  }

  // ---- Read: single escrow lookup ----
  //
  // Reads DataKey::Escrow(Address) directly from contract storage.
  // This is a union type (Rust #[contracttype] enum with a payload
  // variant), built via ContractSpec + NativeUnionVal so the encoding
  // matches the on-chain spec exactly rather than being hand-assembled.
  //
  // NOTE: storage durability (PERSISTENT vs TEMPORARY) for this
  // contract's entries was not confirmed during on-chain inspection.
  // Defaulting to PERSISTENT; verify against a live query before
  // relying on this in production, and switch to TEMPORARY if the
  // first attempt returns null for a known-active escrow.

  /// Reads the escrow entry for [accountId], or `null` if none exists.
  Future<EscrowedBalance?> getEscrow(String accountId) async {
    final client = await _getClient();
    final spec = client.getContractSpec();

    final dataKeyDef = XdrSCSpecTypeDef.forUdt(XdrSCSpecTypeUDT('DataKey'));
    final key = spec.nativeToXdrSCVal(
      NativeUnionVal('Escrow', values: [accountId]),
      dataKeyDef,
    );

    final entry = await _sorobanServer.getContractData(
      contractId,
      key,
      XdrContractDataDurability.PERSISTENT,
    );

    if (entry == null) return null;

    final value = entry.ledgerEntryDataXdr.contractData?.val;
    if (value == null || value.map == null) {
      throw const StrongholdException(
        'Unexpected escrow storage encoding: expected a struct-as-map '
        'SCVal',
      );
    }

    // EscrowedBalance { account: Address, amount: i128,
    // claim_after: u64 }
    BigInt? amount;
    int? claimAfterSeconds;
    for (final mapEntry in value.map!) {
      switch (mapEntry.key.sym) {
        case 'amount':
          final hi = mapEntry.val.i128?.hi.int64 ?? BigInt.zero;
          final lo = mapEntry.val.i128?.lo.uint64 ?? BigInt.zero;
          amount = (hi << 64) + lo;
        case 'claim_after':
          claimAfterSeconds = mapEntry.val.u64?.uint64.toInt();
      }
    }

    if (amount == null || claimAfterSeconds == null) {
      throw const StrongholdException(
        'Escrow entry missing expected fields',
      );
    }

    return EscrowedBalance(
      accountId: accountId,
      amount: amount,
      claimAfter: DateTime.fromMillisecondsSinceEpoch(
        claimAfterSeconds * 1000,
        isUtc: true,
      ),
    );
  }

  // ---- Write: lock ----
  //
  // fn lock(account: Address, amount: i128, claim_after: u64)
  //   -> Result<(), Error>

  /// Locks [amount] of SHx for [accountId] until [claimAfter].
  Future<void> lock({
    required String accountId,
    required BigInt amount,
    required DateTime claimAfter,
  }) async {
    final client = await _getClient();
    final spec = client.getContractSpec();

    final args = spec.funcArgsToXdrSCValues('lock', {
      'account': accountId,
      'amount': amount,
      'claim_after': claimAfter.toUtc().millisecondsSinceEpoch ~/ 1000,
    });

    try {
      await client.invokeMethod(name: 'lock', args: args);
    } catch (e) {
      throw _mapEscrowError(e);
    }
  }

  // ---- Write: unlock ----
  //
  // fn unlock(account: Address) -> Result<(), Error>
  // Fails with TooEarlyToUnlock (3) if claim_after has not passed yet.

  /// Unlocks the escrow entry for [accountId].
  Future<void> unlock({required String accountId}) async {
    final client = await _getClient();
    final spec = client.getContractSpec();

    final args = spec.funcArgsToXdrSCValues('unlock', {
      'account': accountId,
    });

    try {
      await client.invokeMethod(name: 'unlock', args: args);
    } catch (e) {
      throw _mapEscrowError(e);
    }
  }

  // ---- Write: extend_ttl ----
  //
  // fn extend_ttl(ttl: u32) -> Result<(), Error>

  /// Extends the contract's storage TTL by [ttl] ledgers.
  Future<void> extendTtl({required int ttl}) async {
    final client = await _getClient();
    final spec = client.getContractSpec();

    final args = spec.funcArgsToXdrSCValues('extend_ttl', {'ttl': ttl});

    try {
      await client.invokeMethod(name: 'extend_ttl', args: args);
    } catch (e) {
      throw _mapEscrowError(e);
    }
  }

  // ---- Error Mapping ----
  //
  // TODO(nemorixgroup): the exact shape of the contract error inside a
  // failed GetTransactionResponse/simulation result needs to be
  // confirmed against a real failing call (e.g. calling unlock before
  // claim_after) before this mapping can be trusted. Currently a
  // best-effort string match; replace with structured extraction from
  // response.resultXdr once verified.
  StrongholdException _mapEscrowError(Object error) {
    final message = error.toString();
    if (message.contains('ClaimAfterInPast')) {
      return const EscrowException(
        EscrowErrorCode.claimAfterInPast,
        'claim_after is in the past',
      );
    }
    if (message.contains('LockupTooLong')) {
      return const EscrowException(
        EscrowErrorCode.lockupTooLong,
        'Requested lockup exceeds max_lockup_duration',
      );
    }
    if (message.contains('TooEarlyToUnlock')) {
      return const EscrowException(
        EscrowErrorCode.tooEarlyToUnlock,
        'claim_after has not passed yet',
      );
    }
    if (message.contains('EscrowNotFound')) {
      return const EscrowException(
        EscrowErrorCode.escrowNotFound,
        'No escrow entry for this account',
      );
    }
    if (message.contains('EscrowAlreadyExists')) {
      return const EscrowException(
        EscrowErrorCode.escrowAlreadyExists,
        'An escrow entry already exists for this account',
      );
    }
    return StrongholdException('Escrow call failed: $message');
  }
}
