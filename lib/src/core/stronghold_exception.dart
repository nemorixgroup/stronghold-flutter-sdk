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
