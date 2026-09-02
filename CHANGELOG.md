# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## 0.0.4-dev

### Added

- `ShxWallet.establishShxTrustline()`: opens a trustline toward the
  real SHx issuer, completing the `funded` -> `shxReady` transition
- `test/src/asset/shx_asset_test.dart`: unit tests verifying
  `ShxTrustline` builds the correct asset, issuer, and limits

### Design Decisions

- `establishShxTrustline()` is self-authorized by the account being
  upgraded (no separate funding source parameter), unlike
  `createAndFund()`, since the account pays for its own trustline
  reserve out of its existing balance
- The real SHx issuer only exists on Mainnet; any operation
  referencing it fails on Testnet with `op_no_issuer`. This is the
  first method in the SDK that cannot be end-to-end tested on
  Testnet, since every prior method only touched asset-agnostic
  native XLM. Full integration testing is deferred until a funded
  Mainnet test account is available; unit tests cover operation
  construction in the meantime

### Status

Phase 2 in progress. Identity, Testnet/Mainnet funding, and SHx
trustline are implemented and verified.  
Next: balance queries (`getXlmBalance`, `getShxBalance`) or payment
integration.  

## 0.0.3-dev

### Added

- `ShxAccount`, `ShxAccountStatus`: domain model tracking an account
  through its onboarding lifecycle (pending, funded, shxReady)
- `ShxWallet.generate()`, `ShxWallet.createPending()`: keypair
  generation, no network call
- `ShxWallet.fundOnTestnet()`: funds an account via Friendbot
- `ShxWallet.createAndFund()`: creates and funds an account on
  Mainnet (or any network reachable via a caller-supplied
  `StellarSDK`), using a caller-supplied funding source `KeyPair`
- Integration test tagging (`@Tags(['integration'])`) and
  `scripts/test_integration.ps1`, so real-network tests run
  separately from the fast pre-commit gate

### Design Decisions

- `sdk` and `network` are passed as explicit separate parameters in
  `createAndFund()` rather than derived from one another, matching
  the idiomatic pattern used in Soneso's own official example app
- The Mainnet funding source `KeyPair` is a caller-supplied
  parameter; the SDK does not manage or assume any financing plan
- Tests that touch real networks live in separate
  `_integration_test.dart` files, excluded from the default
  `flutter test` run in the pre-commit gate

### Status

Phase 2 in progress. Identity, Testnet funding, and Mainnet
create+fund are implemented and verified (unit and integration tests
passing).  
Next: SHx trustline integration into the `ShxAccount` lifecycle
(`funded` -> `shxReady`).

## 0.0.1-dev

Phase 1 in progress: architecture scaffold complete, escrow contract
client and governance voting builders implemented against a verified
on-chain spec.

### Added

- `StrongholdConstants`: SHx asset code/issuer, SAC contract ID, escrow
contract ID, all verified via `stellar contract inspect` against Mainnet
- `StrongholdEndpoints`: Horizon/Soroban RPC URLs for Testnet; no default
Mainnet Soroban RPC provided, Stellar has no official public one
- `ShxAsset`, `ShxTrustline`, `ShxPayment`: trustline and payment
operation builders for the SHx asset
- `ShxVote`, `ShxGovernance`: `ManageData`-based governance voting
(cast + clear operations), per the official SHx Governance Rules
- `ShxEscrowClient`: client for Stronghold's 60B SHx / 5-year escrow
Soroban contract; `lock`, `unlock`, `extendTtl`, and `getEscrow` (direct
storage read via `DataKey::Escrow(Address)`)
- `EscrowException`, `EscrowErrorCode`: typed error mapping from the
contract's on-chain `Errors` enum
- `scripts/pre_commit.ps1`: format + analyze + test quality gate
- `.github/workflows/ci.yml`: same gate running on every push/PR

### Design Decisions

- Depends on `stellar_flutter_sdk` as a normal pub.dev package instead
of forking it. SHx has no chain of its own, so there is nothing to
fork; forking the base SDK would only duplicate maintenance already
funded by the Stellar Public Goods Program
- The documented "SHx Soroban Contract ID" in Stronghold's own
governance docs turned out to be the auto-generated Stellar Asset
Contract (SAC, standard SEP-41 interface), not custom governance
logic, confirmed by inspecting it live on Mainnet, not by reading
documentation. Governance in this SDK is implemented via classic
`ManageData` operations instead, matching what is actually documented
and used by Stronghold's own voting tool
- Escrow contract bindings are built directly from the on-chain spec
(`stellar contract inspect`), since the contract's source code is not
publicly available for verification

### Known Limitations

- Escrow storage durability (`PERSISTENT` vs `TEMPORARY`) is assumed,
not yet confirmed against a live Testnet read
- Escrow error extraction from a failed transaction currently uses
string matching on the exception message; needs to be replaced with
structured extraction once a real failing call has been observed
- Path payment support (SHx cross-asset conversion) not yet implemented

### Status

Phase 1 in progress. No network interaction tested yet.  
Not ready for production use.  
Next: close out remaining Phase 1 tasks.
