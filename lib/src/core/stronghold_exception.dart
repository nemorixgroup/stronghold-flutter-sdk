/// Exceptions surfaced by this SDK.
library;

// ---- Base Exception ----

class StrongholdException implements Exception {
  final String message;
  const StrongholdException(this.message);

  @override
  String toString() => 'StrongholdException: $message';
}

// ---- Escrow-Specific Errors ----
//
// Mirrors the on-chain contract's `Errors` enum (verified via
// `stellar contract inspect` against Mainnet), so callers get a typed
// Dart exception instead of a raw contract error code.

enum EscrowErrorCode {
  claimAfterInPast, // Errors::ClaimAfterInPast = 1
  lockupTooLong, // Errors::LockupTooLong = 2
  tooEarlyToUnlock, // Errors::TooEarlyToUnlock = 3
  escrowNotFound, // Errors::EscrowNotFound = 4
  escrowAlreadyExists, // Errors::EscrowAlreadyExists = 5
}

class EscrowException extends StrongholdException {
  final EscrowErrorCode code;
  const EscrowException(this.code, String message) : super(message);
}
