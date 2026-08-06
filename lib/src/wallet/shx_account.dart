/// Domain model representing a Stellar account through its SHx
/// onboarding lifecycle.
library;

import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

// ---- Account Status ----

/// Where an account stands in the SHx onboarding flow.
///
/// Stellar has no single "account exists" boolean the way some other
/// chains do: an account only exists on the ledger once it has
/// received its first XLM payment, and it can only hold SHx once it
/// has separately opened a trustline toward the SHx issuer (see
/// `docs-sdk/phase-2/` for the onboarding design). This enum makes
/// that multi-step reality explicit instead of leaving a UI to guess
/// an account's state from raw balance queries.
enum ShxAccountStatus {
  /// Keypair generated locally; not yet funded on any network.
  pending,

  /// Account exists on the network (has an XLM balance) but has no
  /// SHx trustline yet.
  funded,

  /// Account has a SHx trustline and can send/receive SHx.
  shxReady,
}

// ---- Account ----

/// A Stellar account tracked through its SHx onboarding lifecycle.
///
/// `stellar_flutter_sdk`'s own `KeyPair` and `AccountResponse` types
/// represent a key pair and a ledger snapshot respectively, but
/// neither one tracks *where a developer's own onboarding flow is
/// at*. [ShxAccount] exists to close that gap: it pairs a [KeyPair]
/// with an explicit [ShxAccountStatus], so a wallet UI can render
/// "fund this account" or "activate SHx" without re-deriving that
/// state from scratch on every screen.
class ShxAccount {
  /// Creates a [ShxAccount] wrapping [keyPair] at the given [status].
  const ShxAccount({required this.keyPair, required this.status});

  /// The underlying Stellar keypair.
  final KeyPair keyPair;

  /// Current onboarding status.
  final ShxAccountStatus status;

  /// The account's public Stellar address.
  String get accountId => keyPair.accountId;

  /// Returns a copy of this account with a different [status].
  ShxAccount copyWith({ShxAccountStatus? status}) {
    return ShxAccount(keyPair: keyPair, status: status ?? this.status);
  }
}
