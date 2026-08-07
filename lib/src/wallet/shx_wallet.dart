/// Identity and account-lifecycle helpers for SHx onboarding.
///
/// This is the entry point of Phase 2: a developer should not need to
/// import stellar_flutter_sdk directly for these common operations.
library;

import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';
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
class ShxWallet {
  ShxWallet._();

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
}
