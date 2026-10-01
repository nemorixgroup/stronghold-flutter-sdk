/// Read-only balance queries for a Stellar account.
///
/// Separated from `ShxWallet` because reading an account's state and
/// changing its lifecycle are different responsibilities, the same
/// split already used for `ShxTrustline` and `ShxPayment` within the
/// asset domain. Neither method here signs or submits a transaction;
/// both are plain Horizon reads.
///
/// See: https://developers.stellar.org/docs/data/apis/horizon/api-reference/resources/accounts/object
library;

import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';
import 'package:stronghold_flutter_sdk/src/core/stronghold_exception.dart';
import 'package:stronghold_flutter_sdk/src/core/stronghold_network.dart';

/// Read-only XLM and SHx balance queries.
class ShxBalance {
  ShxBalance._();

  // ---- Native (XLM) Balance ----

  /// Reads [accountId]'s XLM (native) balance from Horizon.
  ///
  /// Example:
  /// ```dart
  /// final xlm = await ShxBalance.getXlmBalance(
  ///   accountId: myAccount.accountId,
  ///   sdk: StellarSDK.TESTNET,
  /// );
  /// ```
  ///
  /// Throws [StrongholdException] if the account cannot be loaded (for
  /// example, if it does not exist on this network).
  static Future<String> getXlmBalance({
    required String accountId,
    required StellarSDK sdk,
  }) async {
    // Load the account's current balances from Horizon.
    final account = await _loadAccountOrThrow(accountId: accountId, sdk: sdk);

    // Native balances have no asset code or issuer; only the type matters.
    final nativeBalance = account.balances.firstWhere(
      (balance) => balance.assetType == Asset.TYPE_NATIVE,
      orElse: () => throw const StrongholdException(
        'Account has no native XLM balance entry',
      ),
    );

    return nativeBalance.balance;
  }

  // ---- SHx Balance ----

  /// Reads [accountId]'s SHx balance from Horizon.
  ///
  /// Returns `'0'` if the account has no trustline toward SHx yet,
  /// rather than throwing, since "no trustline" is an expected,
  /// normal state for an account that has not reached
  /// `ShxAccountStatus.shxReady` (see `ShxWallet.establishShxTrustline`),
  /// not an error condition.
  ///
  /// Matches on both asset code and issuer, not code alone: anyone
  /// can create an unrelated asset also called "SHX" from a different
  /// issuer, and this method must never report a balance in that
  /// lookalike as if it were real SHx.
  ///
  /// Example:
  /// ```dart
  /// final shx = await ShxBalance.getShxBalance(
  ///   accountId: myAccount.accountId,
  ///   sdk: StellarSDK.TESTNET,
  /// );
  /// ```
  ///
  /// Throws [StrongholdException] if the account cannot be loaded (for
  /// example, if it does not exist on this network).
  static Future<String> getShxBalance({
    required String accountId,
    required StellarSDK sdk,
  }) async {
    // Load the account's current balances from Horizon.
    final account = await _loadAccountOrThrow(accountId: accountId, sdk: sdk);

    // Match on asset code AND issuer, never code alone.
    final shxBalance = account.balances.firstWhere(
      (balance) =>
          balance.assetCode == StrongholdConstants.shxAssetCode &&
          balance.assetIssuer == StrongholdConstants.shxIssuerAccountId,
      // Synthetic zero-balance placeholder when no SHx trustline exists;
      // only .balance is ever read from it, the rest of the fields are
      // irrelevant filler.
      orElse: () => Balance(
        Asset.TYPE_NATIVE,
        null,
        null,
        '0',
        null,
        null,
        null,
        null,
        null,
        null,
        null,
        null,
        null,
        null,
      ),
    );

    return shxBalance.balance;
  }

  // ---- Private Helpers ----

  static Future<AccountResponse> _loadAccountOrThrow({
    required String accountId,
    required StellarSDK sdk,
  }) async {
    try {
      return await sdk.accounts.account(accountId);
    } catch (e) {
      throw StrongholdException('Failed to load account $accountId: $e');
    }
  }
}
