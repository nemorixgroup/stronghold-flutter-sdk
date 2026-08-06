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
}
