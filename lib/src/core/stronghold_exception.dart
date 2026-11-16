/// Exceptions surfaced by this SDK.
library;

// ---- Base Exception ----

/// Base exception type for all errors raised by this SDK.
class StrongholdException implements Exception {
  /// Creates a [StrongholdException] with the given [message].
  const StrongholdException(this.message);

  /// Human-readable description of what went wrong.
  final String message;

  @override
  String toString() => 'StrongholdException: $message';
}

// ---- Escrow-Specific Errors ----
//
// Mirrors the on-chain contract's `Errors` enum (verified via
// `stellar contract inspect` against Mainnet), so callers get a typed
// Dart exception instead of a raw contract error code.

/// Error codes mirroring the escrow contract's on-chain `Errors` enum.
enum EscrowErrorCode {
  /// Errors::ClaimAfterInPast = 1
  claimAfterInPast,

  /// Errors::LockupTooLong = 2
  lockupTooLong,

  /// Errors::TooEarlyToUnlock = 3
  tooEarlyToUnlock,

  /// Errors::EscrowNotFound = 4
  escrowNotFound,

  /// Errors::EscrowAlreadyExists = 5
  escrowAlreadyExists,
}

/// Exception raised by `ShxEscrowClient` when the escrow contract
/// rejects a call.
class EscrowException extends StrongholdException {
  /// Creates an [EscrowException] with the given [code] and [message].
  const EscrowException(this.code, super.message);

  /// Which on-chain error was returned.
  final EscrowErrorCode code;
}

// ---- Payment-Specific Errors ----
//
// The codes follow the result codes documented for the Payment operation
// and for transactions in the Stellar documentation, plus a few raised
// by this SDK before anything is sent.

/// Why a SHx payment failed, as reported by `ShxPayment.send`.
///
/// What a failure means for the money depends on where it happened:
///
/// - [invalidAmount], [invalidDestination], [invalidMemo], [sameAccount]
///   and [sourceNotReady] are raised before any network call: nothing
///   was sent.
/// - [destinationNotFound] and [destinationNoTrustline] come either from
///   a lookup made just before submitting (nothing was sent) or from the
///   network rejecting the transaction (none of its operations is
///   applied, although the fee may still be charged).
/// - [outcomeUnknown] is the only code that means the payment may have
///   been applied.
///
/// See: https://developers.stellar.org/docs/data/apis/horizon/api-reference/errors/result-codes/operation-specific/payment
enum ShxPaymentErrorCode {
  /// The amount is not a plain decimal with up to 7 decimals, or it is
  /// zero or above the largest amount Stellar can represent.
  invalidAmount,

  /// The destination is not a valid Stellar account address starting
  /// with G.
  invalidDestination,

  /// The memo is empty or longer than 28 bytes of UTF-8.
  invalidMemo,

  /// The source and the destination are the same account.
  sameAccount,

  /// The source account is not `ShxAccountStatus.shxReady`.
  sourceNotReady,

  /// The destination account does not exist on this network
  /// (`op_no_destination`).
  destinationNotFound,

  /// The destination has no SHx trustline (`op_no_trust`).
  destinationNoTrustline,

  /// The source does not hold enough SHx (`op_underfunded`).
  insufficientShx,

  /// The source does not have enough XLM to pay the fee while keeping
  /// its minimum balance (`tx_insufficient_balance`).
  insufficientXlmForFee,

  /// The destination's trustline limit would be exceeded
  /// (`op_line_full`).
  destinationLimitReached,

  /// The network rejected the payment with a code this SDK does not map
  /// to a more specific reason; see
  /// [ShxPaymentException.transactionResultCode] and
  /// [ShxPaymentException.operationResultCodes].
  rejected,

  /// The SDK did not get a definitive answer from the network, so the
  /// payment may or may not have been applied. Check
  /// [ShxPaymentException.transactionHash] before sending again.
  outcomeUnknown,
}

/// Exception raised by `ShxPayment.send` when a SHx payment fails.
///
/// Callers who build their own payment transactions can classify a
/// failed submission with [ShxPaymentException.fromResultCodes].
///
/// Example:
/// ```dart
/// try {
///   await ShxPayment.send(
///     source: account,
///     destinationAccountId: recipient,
///     amount: '10',
///     sdk: StellarSDK.PUBLIC,
///     network: Network.PUBLIC,
///   );
/// } on ShxPaymentException catch (e) {
///   if (e.code == ShxPaymentErrorCode.outcomeUnknown) {
///     // Do not retry blindly: look up e.transactionHash first.
///   }
/// }
/// ```
class ShxPaymentException extends StrongholdException {
  /// Creates a [ShxPaymentException] with the given [code] and [message].
  const ShxPaymentException(
    this.code,
    super.message, {
    this.transactionHash,
    this.transactionResultCode,
    this.operationResultCodes,
  });

  /// Builds the exception for a payment transaction that the network
  /// rejected, from the result codes Horizon returned.
  ///
  /// [transactionResultCode] is the transaction-level code (for example
  /// `tx_failed`) and [operationResultCodes] the per-operation codes
  /// (for example `op_no_trust`).
  factory ShxPaymentException.fromResultCodes({
    required String transactionHash,
    String? transactionResultCode,
    List<String> operationResultCodes = const [],
  }) {
    final ShxPaymentErrorCode code;
    final String reason;
    if (transactionResultCode == 'tx_insufficient_balance') {
      code = ShxPaymentErrorCode.insufficientXlmForFee;
      reason =
          'The source account does not have enough XLM to pay the fee '
          'while keeping its minimum balance';
    } else if (operationResultCodes.contains('op_no_destination')) {
      code = ShxPaymentErrorCode.destinationNotFound;
      reason = 'The destination account does not exist on this network';
    } else if (operationResultCodes.contains('op_no_trust')) {
      code = ShxPaymentErrorCode.destinationNoTrustline;
      reason = 'The destination account has no SHx trustline';
    } else if (operationResultCodes.contains('op_underfunded')) {
      code = ShxPaymentErrorCode.insufficientShx;
      reason = 'The source account does not hold enough SHx';
    } else if (operationResultCodes.contains('op_line_full')) {
      code = ShxPaymentErrorCode.destinationLimitReached;
      reason = "The payment would exceed the destination's SHx trustline limit";
    } else {
      code = ShxPaymentErrorCode.rejected;
      reason = 'The network rejected the payment';
    }

    return ShxPaymentException(
      code,
      '$reason (transaction=$transactionResultCode, '
      'operations=$operationResultCodes)',
      transactionHash: transactionHash,
      transactionResultCode: transactionResultCode,
      operationResultCodes: operationResultCodes,
    );
  }

  /// Which failure this is.
  final ShxPaymentErrorCode code;

  /// Hash of the transaction that was (or may have been) submitted, in
  /// lowercase hex. Null when the failure happened before a transaction
  /// was built.
  final String? transactionHash;

  /// Transaction-level result code from Horizon (for example
  /// `tx_failed`), when the network returned one.
  final String? transactionResultCode;

  /// Operation-level result codes from Horizon (for example
  /// `op_no_trust`), when the network returned them.
  final List<String>? operationResultCodes;

  @override
  String toString() => 'ShxPaymentException(${code.name}): $message';
}
