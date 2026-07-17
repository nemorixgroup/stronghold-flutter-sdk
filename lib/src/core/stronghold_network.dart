/// Network configuration for the SHx ecosystem.
///
/// SHx does not have its own network; it is an asset issued on Stellar.
/// This class centralizes the Stellar network parameters and the verified
/// on-chain identifiers this SDK depends on, so nothing is hardcoded
/// redundantly across the asset, governance, or escrow modules.
library;

// ---- Network Selection ----

enum StrongholdNetwork { mainnet, testnet }

// ---- SHx Ecosystem Constants ----

class StrongholdConstants {
  StrongholdConstants._();

  /// SHx asset code on Stellar.
  static const String shxAssetCode = 'SHX';

  /// SHx issuer account on the Public Global Stellar Network.
  /// Source: https://docs.shx.stronghold.co/shx/shx-governance-rules
  static const String shxIssuerAccountId =
      'GDSTRSHXHGJ7ZIVRBXEYE5Q74XUVCUSEKEBR7UCHEUUEK72N7I7KJ6JH';

  /// SHx decimal precision on Stellar.
  static const int shxDecimals = 7;

  /// Auto-generated Stellar Asset Contract (SAC) wrapping the SHx classic
  /// asset for Soroban. Standard SEP-41 interface only; NOT a custom
  /// governance or lock contract. Verified on-chain via `stellar contract
  /// inspect` against Mainnet (source: stellar/rs-soroban-env, protocol-level
  /// code, not Stronghold-authored).
  static const String shxSacContractId =
      'CCKCKCPHYVXQD4NECBFJTFSCU2AMSJGCNG4O6K4JVRE2BLPR7WNDBQIQ';

  /// Stronghold's custom 60B SHx / 5-year escrow contract. Verified on-chain
  /// spec: lock(account, amount, claim_after), unlock(account),
  /// extend_ttl(ttl). Source code not publicly verified (no Contract Source
  /// Validation SEP attestation found as of this writing).
  static const String shxEscrowContractId =
      'CCA5HAZCPEYXD7JBKAJCVUZUXAK7V5ZFU3QMJO33OJH2OHL3OGLS2P7M';
}

// ---- RPC / Horizon Endpoints ----
//
// Stellar does not provide an official public Soroban RPC for Mainnet.
// Callers MUST supply their own RPC URL (see the Knowledge Base, Module 06,
// for provider options). Testnet uses the SDF's public RPC.

class StrongholdEndpoints {
  StrongholdEndpoints._();

  static const String testnetHorizonUrl = 'https://horizon-testnet.stellar.org';
  static const String testnetSorobanRpcUrl =
      'https://soroban-testnet.stellar.org';

  static const String mainnetHorizonUrl = 'https://horizon.stellar.org';

  /// No default provided intentionally. Pass your own Mainnet RPC provider
  /// URL when constructing a client for [StrongholdNetwork.mainnet].
  static const String? mainnetSorobanRpcUrl = null;

  static const String mainnetPassphrase =
      'Public Global Stellar Network ; September 2015';
  static const String testnetPassphrase = 'Test SDF Network ; September 2015';
}
