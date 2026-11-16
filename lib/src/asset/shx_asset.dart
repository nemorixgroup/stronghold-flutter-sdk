/// SHx asset operations on Stellar: trustlines and payments.
///
/// API confirmed against stellar_flutter_sdk v3.3.0 documentation
/// (Soneso/stellar_flutter_sdk, documentation/soroban.md and README
/// quick examples): Asset.createNonNativeAsset,
/// ChangeTrustOperationBuilder, PaymentOperationBuilder.
library;

import 'dart:convert';

import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';
import 'package:stronghold_flutter_sdk/src/core/stronghold_exception.dart';
import 'package:stronghold_flutter_sdk/src/core/stronghold_network.dart';
import 'package:stronghold_flutter_sdk/src/wallet/shx_account.dart';

// ---- The SHx Asset ----

/// The SHx asset, ready to use in any Stellar operation.
class ShxAsset {
  ShxAsset._();

  /// The SHx asset descriptor.
  static Asset get asset => Asset.createNonNativeAsset(
    StrongholdConstants.shxAssetCode,
    StrongholdConstants.shxIssuerAccountId,
  );
}

// ---- Trustlines ----
//
// A Stellar account cannot receive SHx until it establishes a trustline
// toward the SHx issuer. This is a mandatory first step, not an edge
// case.

/// Helpers for establishing or removing a trustline toward SHx.
class ShxTrustline {
  ShxTrustline._();

  /// Builds a ChangeTrust operation authorizing the source account to
  /// hold SHx, up to [limit] (defaults to the SDK's maximum
  /// representable amount).
  static ChangeTrustOperationBuilder buildEstablishOperation({
    String? limit,
  }) {
    return ChangeTrustOperationBuilder(
      ShxAsset.asset,
      limit ?? ChangeTrustOperationBuilder.MAX_LIMIT,
    );
  }

  /// Builds a ChangeTrust operation removing the trustline (limit
  /// "0"). Only succeeds if the account's SHx balance is zero.
  static ChangeTrustOperationBuilder buildRemoveOperation() {
    return ChangeTrustOperationBuilder(ShxAsset.asset, '0');
  }
}

// ---- Payments ----

/// Sends SHx between Stellar accounts, or builds the payment operation
/// for callers who assemble their own transactions.
///
/// SHx is a standard Stellar asset, so a payment is a classic Stellar
/// Payment operation: Stronghold does not publish a separate API for
/// it. [send] wraps that operation with the checks a wallet needs: it
/// validates the input, confirms the destination can receive SHx before
/// spending a fee, and reports failures as a typed
/// [ShxPaymentException].
///
/// Only classic account addresses (starting with G) are supported as
/// destinations. Muxed (M) and contract (C) addresses are rejected.
///
/// Example:
/// ```dart
/// final txHash = await ShxPayment.send(
///   source: myShxReadyAccount,
///   destinationAccountId: recipientAccountId,
///   amount: '10.5',
///   sdk: StellarSDK.PUBLIC,
///   network: Network.PUBLIC,
///   memo: 'invoice 1042',
/// );
/// ```
///
/// See: https://developers.stellar.org/docs/learn/fundamentals/transactions/list-of-operations#payment
class ShxPayment {
  ShxPayment._();

  /// Maximum length of a text memo, in UTF-8 bytes.
  static const int maxMemoBytes = 28;

  static final RegExp _accountIdPattern = RegExp(r'^G[A-Z2-7]{55}$');
  static final RegExp _amountPattern = RegExp(r'^(\d+)(?:\.(\d{1,7}))?$');
  static final BigInt _stroopsPerUnit = BigInt.from(10000000);
  static final BigInt _maxStroops = BigInt.parse('9223372036854775807');

  /// Builds a simple SHx payment operation. The destination account
  /// MUST already have a trustline toward the SHx issuer (see
  /// [ShxTrustline]).
  static PaymentOperationBuilder buildPaymentOperation({
    required String destinationAccountId,
    required String amount,
  }) {
    return PaymentOperationBuilder(
      destinationAccountId,
      ShxAsset.asset,
      amount,
    );
  }

  /// Sends [amount] of SHx from [source] to [destinationAccountId], and
  /// returns the transaction hash (lowercase hex).
  ///
  /// [source] must be [ShxAccountStatus.shxReady]. [amount] is a plain
  /// decimal such as `'10'` or `'10.5'`, with up to 7 decimals, greater
  /// than zero and at most 922337203685.4775807; forms like `'.5'`,
  /// `'1.'` or `'1e3'` are rejected. The optional [memo] is a text memo
  /// of 1 to [maxMemoBytes] bytes of UTF-8 (exchanges that list SHx
  /// often use memos to credit deposits; pass null for none).
  ///
  /// Before submitting, the destination is looked up, so a missing
  /// account or a missing SHx trustline is reported without paying a
  /// fee for a payment that could not work. That lookup is not atomic
  /// with the submission: the network remains the final authority.
  ///
  /// This method never retries. Any exception thrown before the
  /// transaction is submitted means nothing was sent. Only
  /// [ShxPaymentErrorCode.outcomeUnknown] means the payment may have
  /// been applied: look up `transactionHash` on the network before
  /// sending again, because resubmitting blindly can pay twice.
  ///
  /// The real SHx issuer only exists on Mainnet, so a successful payment
  /// can only happen there.
  ///
  /// See: https://developers.stellar.org/docs/data/apis/horizon/api-reference/errors/error-handling
  ///
  /// Example:
  /// ```dart
  /// final txHash = await ShxPayment.send(
  ///   source: myShxReadyAccount,
  ///   destinationAccountId: recipientAccountId,
  ///   amount: '10.5',
  ///   sdk: StellarSDK.PUBLIC,
  ///   network: Network.PUBLIC,
  /// );
  /// ```
  ///
  /// Throws [ShxPaymentException] for invalid input, for a destination
  /// that cannot receive SHx, and when the network rejects the payment
  /// or does not answer. Throws [StrongholdException] if an account
  /// lookup fails for another reason (nothing was sent).
  static Future<String> send({
    required ShxAccount source,
    required String destinationAccountId,
    required String amount,
    required StellarSDK sdk,
    required Network network,
    String? memo,
  }) async {
    // Only an account that already holds the SHx trustline can pay SHx.
    if (source.status != ShxAccountStatus.shxReady) {
      throw ShxPaymentException(
        ShxPaymentErrorCode.sourceNotReady,
        'The source account must be shxReady, but it is '
        '${source.status.name}',
      );
    }

    // Reject malformed input before any network call.
    if (!_isValidAccountId(destinationAccountId)) {
      throw ShxPaymentException(
        ShxPaymentErrorCode.invalidDestination,
        '"$destinationAccountId" is not a valid Stellar account address; '
        'only addresses starting with G are supported',
      );
    }
    if (destinationAccountId == source.accountId) {
      throw const ShxPaymentException(
        ShxPaymentErrorCode.sameAccount,
        'The source and the destination are the same account',
      );
    }
    if (!_isValidAmount(amount)) {
      throw ShxPaymentException(
        ShxPaymentErrorCode.invalidAmount,
        '"$amount" is not a valid amount: use a plain decimal with up to '
        '7 decimals, greater than zero',
      );
    }
    if (memo != null) {
      final memoBytes = utf8.encode(memo).length;
      if (memoBytes == 0 || memoBytes > maxMemoBytes) {
        throw const ShxPaymentException(
          ShxPaymentErrorCode.invalidMemo,
          'The memo must be between 1 and $maxMemoBytes bytes of UTF-8',
        );
      }
    }

    // Confirm the destination exists and holds the SHx trustline.
    final destination = await _loadDestination(sdk, destinationAccountId);
    final hasShxTrustline = destination.balances.any(
      (balance) =>
          balance.assetCode == StrongholdConstants.shxAssetCode &&
          balance.assetIssuer == StrongholdConstants.shxIssuerAccountId,
    );
    if (!hasShxTrustline) {
      throw ShxPaymentException(
        ShxPaymentErrorCode.destinationNoTrustline,
        'The destination account $destinationAccountId has no SHx '
        'trustline, so it cannot receive SHx',
      );
    }

    // Load the source account's current sequence number from Horizon.
    final sourceAccount = await _loadSource(sdk, source.accountId);

    // Build the payment, with the optional text memo.
    final paymentOp = buildPaymentOperation(
      destinationAccountId: destinationAccountId,
      amount: amount,
    ).build();
    final builder = TransactionBuilder(sourceAccount).addOperation(paymentOp);
    if (memo != null) {
      builder.addMemo(Memo.text(memo));
    }

    // Sign, and compute the hash now: it identifies this transaction even
    // if the network never answers.
    final transaction = builder.build()..sign(source.keyPair, network);
    final hash = Util.bytesToHex(transaction.hash(network));

    // Submit once; an exception here leaves the outcome unknown.
    final SubmitTransactionResponse response;
    try {
      response = await sdk.submitTransaction(transaction);
    } catch (e) {
      throw ShxPaymentException(
        ShxPaymentErrorCode.outcomeUnknown,
        'The network did not give a definitive answer, so the payment may '
        'or may not have been applied. Do not retry blindly: look up '
        'transaction $hash first. Cause: $e',
        transactionHash: hash,
      );
    }

    if (response.success) {
      return hash;
    }

    // A rejection is only definitive if the network returned result codes.
    final codes = response.extras?.resultCodes;
    final transactionCode = codes?.transactionResultCode;
    final operationCodes =
        codes?.operationsResultCodes?.whereType<String>().toList() ??
        const <String>[];
    if (transactionCode == null && operationCodes.isEmpty) {
      throw ShxPaymentException(
        ShxPaymentErrorCode.outcomeUnknown,
        'The network reported a failure without result codes, so the '
        'payment may or may not have been applied. Do not retry blindly: '
        'look up transaction $hash first.',
        transactionHash: hash,
      );
    }
    throw ShxPaymentException.fromResultCodes(
      transactionHash: hash,
      transactionResultCode: transactionCode,
      operationResultCodes: operationCodes,
    );
  }

  // ---- Private Helpers ----

  static bool _isValidAccountId(String accountId) {
    if (!_accountIdPattern.hasMatch(accountId)) {
      return false;
    }
    // The pattern checks the shape; decoding also checks the checksum.
    try {
      KeyPair.fromAccountId(accountId);
      return true;
    } on Object {
      return false;
    }
  }

  static bool _isValidAmount(String amount) {
    final match = _amountPattern.firstMatch(amount);
    if (match == null) {
      return false;
    }
    // Exact arithmetic in stroops: a double cannot hold 7 decimals at the
    // top of the range.
    final whole = BigInt.parse(match.group(1)!);
    final fraction = BigInt.parse((match.group(2) ?? '').padRight(7, '0'));
    final stroops = whole * _stroopsPerUnit + fraction;
    return stroops > BigInt.zero && stroops <= _maxStroops;
  }

  static Future<AccountResponse> _loadDestination(
    StellarSDK sdk,
    String accountId,
  ) async {
    try {
      return await sdk.accounts.account(accountId);
    } on ErrorResponse catch (e) {
      if (e.code == 404) {
        throw ShxPaymentException(
          ShxPaymentErrorCode.destinationNotFound,
          'The destination account $accountId does not exist on this '
          'network; it must be created and funded first',
        );
      }
      throw StrongholdException(
        'Failed to load destination account $accountId: HTTP ${e.code}',
      );
    } catch (e) {
      throw StrongholdException(
        'Failed to load destination account $accountId: $e',
      );
    }
  }

  static Future<AccountResponse> _loadSource(
    StellarSDK sdk,
    String accountId,
  ) async {
    try {
      return await sdk.accounts.account(accountId);
    } catch (e) {
      throw StrongholdException(
        'Failed to load source account $accountId: $e',
      );
    }
  }

  // TODO(nemorixgroup): add buildPathPaymentOperation wrapping
  // PathPaymentStrictSendOperationBuilder /
  // PathPaymentStrictReceiveOperationBuilder for cross-asset SHx
  // conversions (relevant to the NemorixPay corridor use case).
}
