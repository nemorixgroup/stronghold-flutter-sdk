/// Data models mirroring the escrow contract's on-chain types.
///
/// Verified via `stellar contract inspect` against
/// CCA5HAZCPEYXD7JBKAJCVUZUXAK7V5ZFU3QMJO33OJH2OHL3OGLS2P7M on Mainnet.
/// Source code for the contract itself is not publicly available; these
/// models are derived solely from the on-chain contract spec
/// (functions, structs, enums), not from a source repository.
library;

// ---- EscrowedBalance ----
//
// #[contracttype]
// struct EscrowedBalance { account: Address, amount: i128, claim_after: u64 }

/// A single escrow entry as stored on-chain.
class EscrowedBalance {
  /// Creates an [EscrowedBalance].
  const EscrowedBalance({
    required this.accountId,
    required this.amount,
    required this.claimAfter,
  });

  /// The account this escrow belongs to.
  final String accountId;

  /// The locked amount, in stroops (SHx has 7 decimals).
  final BigInt amount;

  /// The moment this escrow becomes claimable.
  final DateTime claimAfter;
}

// ---- Events ----
//
// #[contracttype] struct EscrowLockEvent { amount: i128, claim_after: u64 }
// #[contracttype] struct EscrowUnlockEvent { amount: i128 }

/// Event emitted by the contract when SHx is locked into escrow.
class EscrowLockEvent {
  /// Creates an [EscrowLockEvent].
  const EscrowLockEvent({required this.amount, required this.claimAfter});

  /// The amount locked.
  final BigInt amount;

  /// The moment this escrow becomes claimable.
  final DateTime claimAfter;
}

/// Event emitted by the contract when SHx is released from escrow.
class EscrowUnlockEvent {
  /// Creates an [EscrowUnlockEvent].
  const EscrowUnlockEvent({required this.amount});

  /// The amount released.
  final BigInt amount;
}
