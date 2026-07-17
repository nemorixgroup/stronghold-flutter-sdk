/// Network configuration for the SHx ecosystem.
///
/// SHx does not have its own network; it is an asset issued on Stellar.
/// This class centralizes the Stellar network parameters and the verified
/// on-chain identifiers this SDK depends on, so nothing is hardcoded
/// redundantly across the asset, governance, or escrow modules.
library;

// ---- Network Selection ----

/// The Stellar network this SDK talks to.
enum StrongholdNetwork {
  /// The Stellar Public Global Network (production).
  mainnet,

  /// The Stellar Testnet.
  testnet,
}

// ---- SHx Ecosystem Constants ----

/// Verified on-chain identifiers for the SHx ecosystem.
class StrongholdConstants {
  StrongholdConstants._();

  /// SHx asset code on Stellar.
  static const String shxAssetCode = 'SHX';

  /// SHx issuer account on the Public Global Stellar Network.
  ///
  /// Source: https://docs.shx.stronghold.co/shx/shx-governance-rules
  static const String shxIssuerAccountId =
      'GDSTRSHXHGJ7ZIVRBXEYE5Q74XUVCUSEKEBR7UCHEUUEK72N7I7KJ6JH';

  /// SHx decimal precision on Stellar.
  static const int shxDecimals = 7;

  /// Auto-generated Stellar Asset Contract (SAC) wrapping the SHx
  /// classic asset for Soroban.
  ///
  /// Standard SEP-41 interface only; NOT a custom governance or lock
  /// contract. Verified on-chain via `stellar contract inspect` against
  /// Mainnet (source: stellar/rs-soroban-env, protocol-level code, not
  /// Stronghold-authored).
  static const String shxSacContractId =
      'CCKCKCPHYVXQD4NECBFJTFSCU2AMSJGCNG4O6K4JVRE2BLPR7WNDBQIQ';

  /// Stronghold's custom 60B SHx / 5-year escrow contract.
  ///
  /// Verified on-chain spec: lock(account, amount, claim_after),
  /// unlock(account), extend_ttl(ttl). Source code not publicly verified
  /// (no Contract Source Validation SEP attestation found as of this
  /// writing).
  static const String shxEscrowContractId =
      'CCA5HAZCPEYXD7JBKAJCVUZUXAK7V5ZFU3QMJO33OJH2OHL3OGLS2P7M';
}

// ---- RPC / Horizon Endpoints ----
//
// Stellar does not provide an official public Soroban RPC for Mainnet.
// Callers MUST supply their own RPC URL (see the Knowledge Base, Module
// 06, for provider options). Testnet uses the SDF's public RPC.

/// Known Horizon and Soroban RPC endpoints.
class StrongholdEndpoints {
  StrongholdEndpoints._();

  /// Horizon URL for Testnet.
  static const String testnetHorizonUrl = 'https://horizon-testnet.stellar.org';

  /// Soroban RPC URL for Testnet.
  static const String testnetSorobanRpcUrl =
      'https://soroban-testnet.stellar.org';

  /// Horizon URL for Mainnet.
  static const String mainnetHorizonUrl = 'https://horizon.stellar.org';

  /// No default provided intentionally. Pass your own Mainnet RPC
  /// provider URL when constructing a client for
  /// [StrongholdNetwork.mainnet].
  static const String? mainnetSorobanRpcUrl = null;

  /// Network passphrase for Mainnet.
  static const String mainnetPassphrase =
      'Public Global Stellar Network ; September 2015';

  /// Network passphrase for Testnet.
  static const String testnetPassphrase = 'Test SDF Network ; September 2015';
}
