/// Identity and account-lifecycle helpers for SHx onboarding.
///
/// This is the entry point of Phase 2: a developer should not need to
/// import stellar_flutter_sdk directly for these common operations.
library;

import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';
import 'package:stronghold_flutter_sdk/src/asset/shx_asset.dart';
import 'package:stronghold_flutter_sdk/src/core/stronghold_exception.dart';
import 'package:stronghold_flutter_sdk/src/wallet/shx_account.dart';

// ---- Identity ----

/// Account creation and lifecycle helpers.
///
/// On Stellar, generating a key pair and having a usable account are
/// two different things: a freshly generated key pair does not exist
/// on the ledger until it receives its first XLM payment (see
/// https://developers.stellar.org/docs/learn/fundamentals/stellar-data-structures/accounts#account-creation).
/// [ShxWallet] is designed around that reality as a set of small,
/// composable steps, generate, fund, become SHx-ready, rather than a
/// single opinionated "create account" call, so a developer can enter
/// at whichever step matches their app's own funding flow (see
/// `docs-sdk/phase-2/` for the full design rationale).
///
/// Example:
/// ```dart
/// final pending = ShxWallet.createPending();
/// final funded = await ShxWallet.fundOnTestnet(pending);
/// ```
class ShxWallet {
  ShxWallet._();

  // ---- Constants ----

  /// Minimum starting balance, in XLM, for an account that will hold SHx.
  ///
  /// Two base reserves for the account itself plus one for the SHx
  /// trustline, at today's base reserve of 0.5 XLM each (3 x 0.5 = 1.5).
  /// The base reserve is set by network vote and may change, so treat
  /// this as the current value, not a permanent guarantee; Horizon
  /// remains the final authority and rejects an underfunded account.
  ///
  /// See: https://developers.stellar.org/docs/learn/fundamentals/lumens#minimum-balance
  static const String minimumBootstrapBalance = '1.5';

  // ---- Identity ----

  /// Generates a new Stellar keypair. No network call; the account
  /// does not exist on any ledger until it is funded (see
  /// [createPending], and later `fundOnTestnet` / `createAndFund`).
  static KeyPair generate() {
    return KeyPair.random();
  }

  /// Generates a new keypair and wraps it as a [ShxAccount] with
  /// [ShxAccountStatus.pending]. Use this when the app needs to show
  /// the user their new address (for example, so someone else can
  /// fund it) before any network interaction happens.
  static ShxAccount createPending() {
    return ShxAccount(keyPair: generate(), status: ShxAccountStatus.pending);
  }

  // ---- Create + Fund (Testnet) ----

  /// Funds [account] on Testnet via Friendbot, Stellar's testnet
  /// faucet, and returns it updated to [ShxAccountStatus.funded].
  ///
  /// This exists as its own step, separate from [createPending] and
  /// separate from establishing a SHx trustline, because on Stellar
  /// "existing" and "SHx-ready" are genuinely two different states: an
  /// account only exists on the ledger once it holds XLM, and only
  /// gains the ability to hold SHx once it separately opens a
  /// trustline (see `ShxTrustline`). Friendbot is Testnet-only; for
  /// Mainnet, use `createAndFund` with a caller-supplied funding
  /// source, since there is no faucet on a live network.
  ///
  /// See: https://developers.stellar.org/docs/learn/fundamentals/networks#friendbot
  ///
  /// Throws [StrongholdException] if Friendbot declines to fund the
  /// account.
  static Future<ShxAccount> fundOnTestnet(ShxAccount account) async {
    final funded = await FriendBot.fundTestAccount(account.accountId);
    if (!funded) {
      throw const StrongholdException(
        'Friendbot declined to fund the account',
      );
    }
    return account.copyWith(status: ShxAccountStatus.funded);
  }

  // ---- Create + Fund (Mainnet) ----

  /// Creates and funds [account] on Mainnet (or any network reachable
  /// via [sdk]), using [fundingSourceKeyPair] as the paying account.
  ///
  /// Unlike [fundOnTestnet], there is no faucet on a live network: the
  /// starting balance has to come from somewhere real, so the caller
  /// supplies the funding keypair explicitly. This SDK does not manage
  /// or assume any financing plan (treasury account, user purchase,
  /// exchange withdrawal); it only builds and submits the
  /// CreateAccountOperation once the caller has decided where the XLM
  /// comes from.
  ///
  /// [startingBalance] should account for Stellar's minimum balance
  /// reserve plus any trustlines the account will open afterward (each
  /// trustline adds its own reserve requirement); this SDK does not
  /// pick a default, since that number depends on what the account will
  /// be used for.
  ///
  /// See: https://developers.stellar.org/docs/learn/fundamentals/stellar-data-structures/accounts#creating-an-account
  ///
  /// Throws [StrongholdException] if the transaction is not accepted by
  /// the network.
  static Future<ShxAccount> createAndFund({
    required ShxAccount account,
    required StellarSDK sdk,
    required Network network,
    required KeyPair fundingSourceKeyPair,
    required String startingBalance,
  }) async {
    // Load the funding account's current sequence number from Horizon.
    final fundingAccount = await sdk.accounts.account(
      fundingSourceKeyPair.accountId,
    );

    // Build the operation that creates and funds the new account.
    final createAccountOp = CreateAccountOperationBuilder(
      account.accountId,
      startingBalance,
    ).build();

    // Build the transaction with the funding account as source, and sign it.
    final transaction =
        TransactionBuilder(
            fundingAccount,
          ).addOperation(createAccountOp).build()
          ..sign(fundingSourceKeyPair, network);

    // Submit to the network and confirm it was accepted.
    final response = await sdk.submitTransaction(transaction);
    if (!response.success) {
      throw const StrongholdException(
        'Failed to create and fund account on Mainnet',
      );
    }

    // Only now can the account be considered funded.
    return account.copyWith(status: ShxAccountStatus.funded);
  }

  // ---- Establish SHx Trustline ----

  /// Opens a trustline from [account] toward the SHx issuer, and
  /// returns it updated to [ShxAccountStatus.shxReady].
  ///
  /// A funded Stellar account still cannot hold SHx until it explicitly
  /// trusts the issuer; this is the step that closes that gap, using
  /// the operation already defined in [ShxTrustline.buildEstablishOperation].
  /// Unlike [createAndFund], the account authorizes this itself: no
  /// separate funding source is involved, the trustline is paid for out
  /// of the account's own existing balance (it adds to that account's
  /// minimum reserve requirement going forward).
  ///
  /// See: https://developers.stellar.org/docs/tokens/control-asset-access#trustlines
  ///
  /// Example:
  /// ```dart
  /// final funded = await ShxWallet.fundOnTestnet(ShxWallet.createPending());
  /// final ready = await ShxWallet.establishShxTrustline(
  ///   account: funded,
  ///   sdk: StellarSDK.TESTNET,
  ///   network: Network.TESTNET,
  /// );
  /// ```
  ///
  /// Throws [StrongholdException] if the transaction is not accepted by
  /// the network (for example, insufficient XLM to cover the added
  /// reserve).
  static Future<ShxAccount> establishShxTrustline({
    required ShxAccount account,
    required StellarSDK sdk,
    required Network network,
  }) async {
    // Load the account's current sequence number from Horizon.
    final loadedAccount = await sdk.accounts.account(account.accountId);

    // Build the ChangeTrust operation toward the SHx issuer.
    final trustOp = ShxTrustline.buildEstablishOperation().build();

    // Build the transaction with the account as its own source, and sign it.
    final transaction = TransactionBuilder(
      loadedAccount,
    ).addOperation(trustOp).build()..sign(account.keyPair, network);

    // Submit to the network and confirm it was accepted.
    final response = await sdk.submitTransaction(transaction);
    if (!response.success) {
      throw StrongholdException(
        'Failed to establish SHx trustline: '
        'transaction=${response.extras?.resultCodes?.transactionResultCode}, '
        'operations=${response.extras?.resultCodes?.operationsResultCodes}',
      );
    }

    // Only now can the account be considered SHx-ready.
    return account.copyWith(status: ShxAccountStatus.shxReady);
  }

  // ---- Bootstrap (Mainnet) ----

  /// Takes a [ShxAccount] from [ShxAccountStatus.pending] to
  /// [ShxAccountStatus.shxReady] in a single atomic transaction: it
  /// creates and funds the account, then opens its SHx trustline.
  ///
  /// Both steps travel in one transaction, so they either both happen
  /// or neither does; there is no half-onboarded state on the network.
  /// The price of that guarantee is that both secrets must sign in the
  /// same place: [fundingSourceKeyPair] (which also pays the fee) and
  /// the new account's own key. When those keys live on different
  /// devices (for example, a backend funds and a phone owns the
  /// account), use [createAndFund] and [establishShxTrustline] as
  /// separate steps instead.
  ///
  /// [startingBalance] is required, in XLM, and must be at least
  /// [minimumBootstrapBalance]. Add headroom on top of that: an account
  /// holding exactly the minimum has no spendable balance left for later
  /// transactions, and this SDK does not choose that headroom for you.
  ///
  /// This only works against Mainnet: the SHx issuer does not exist on
  /// Testnet, so the trustline step fails there with `op_no_issuer` and
  /// the whole transaction is rolled back (see
  /// `docs-sdk/phase-2/shx-trustline/`).
  ///
  /// See: https://developers.stellar.org/docs/learn/fundamentals/transactions/operations-and-transactions
  ///
  /// Example:
  /// ```dart
  /// final ready = await ShxWallet.bootstrapForShx(
  ///   account: ShxWallet.createPending(),
  ///   sdk: StellarSDK.PUBLIC,
  ///   network: Network.PUBLIC,
  ///   fundingSourceKeyPair: myFundingKeyPair,
  ///   startingBalance: '2',
  /// );
  /// ```
  ///
  /// Throws [StrongholdException] if [account] is not pending, if
  /// [startingBalance] is not a valid amount or is below
  /// [minimumBootstrapBalance], or if the network rejects the
  /// transaction.
  static Future<ShxAccount> bootstrapForShx({
    required ShxAccount account,
    required StellarSDK sdk,
    required Network network,
    required KeyPair fundingSourceKeyPair,
    required String startingBalance,
  }) async {
    // Only a pending account can be created; fail early otherwise.
    if (account.status != ShxAccountStatus.pending) {
      throw StrongholdException(
        'bootstrapForShx requires a pending account, '
        'got ${account.status.name}',
      );
    }

    // Reject invalid or underfunded amounts before touching the network.
    final amount = double.tryParse(startingBalance);
    if (amount == null ||
        !amount.isFinite ||
        amount < double.parse(minimumBootstrapBalance)) {
      throw StrongholdException(
        'startingBalance must be a number of at least '
        '$minimumBootstrapBalance XLM, got "$startingBalance"',
      );
    }

    // Load the funding account's current sequence number from Horizon.
    final fundingAccount = await sdk.accounts.account(
      fundingSourceKeyPair.accountId,
    );

    // Operation 1: create and fund the new account (source: the funder).
    final createAccountOp = CreateAccountOperationBuilder(
      account.accountId,
      startingBalance,
    ).build();

    // Operation 2: open the SHx trustline with the NEW account as its
    // source; it already exists by then because operations run in order.
    final trustOp = ShxTrustline.buildEstablishOperation()
        .setSourceAccount(account.accountId)
        .build();

    // One transaction, signed by both the funder and the new account.
    final transaction =
        TransactionBuilder(
            fundingAccount,
          ).addOperation(createAccountOp).addOperation(trustOp).build()
          ..sign(fundingSourceKeyPair, network)
          ..sign(account.keyPair, network);

    // Submit; on failure nothing is applied, including the creation.
    final response = await sdk.submitTransaction(transaction);
    if (!response.success) {
      throw StrongholdException(
        'Failed to bootstrap SHx account: '
        'transaction=${response.extras?.resultCodes?.transactionResultCode}, '
        'operations=${response.extras?.resultCodes?.operationsResultCodes}',
      );
    }

    // Both steps were applied together, so the account is SHx-ready.
    return account.copyWith(status: ShxAccountStatus.shxReady);
  }
}
