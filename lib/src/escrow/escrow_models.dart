/// Data models mirroring the escrow contract's on-chain types.
///
/// Verified via `stellar contract inspect` against
/// CCA5HAZCPEYXD7JBKAJCVUZUXAK7V5ZFU3QMJO33OJH2OHL3OGLS2P7M on Mainnet.
/// Source code for the contract itself is not publicly available; these
/// models are derived solely from the on-chain contract spec (functions,
/// structs, enums), not from a source repository.
library;

// ---- EscrowedBalance ----
//
// #[contracttype]
// struct EscrowedBalance { account: Address, amount: i128, claim_after: u64 }

class EscrowedBalance {
  final String accountId;
  final BigInt amount;
  final DateTime claimAfter;

  const EscrowedBalance({
    required this.accountId,
    required this.amount,
    required this.claimAfter,
  });
}

// ---- Events ----
//
// #[contracttype] struct EscrowLockEvent { amount: i128, claim_after: u64 }
// #[contracttype] struct EscrowUnlockEvent { amount: i128 }

class EscrowLockEvent {
  final BigInt amount;
  final DateTime claimAfter;
  const EscrowLockEvent({required this.amount, required this.claimAfter});
}

class EscrowUnlockEvent {
  final BigInt amount;
  const EscrowUnlockEvent({required this.amount});
}
