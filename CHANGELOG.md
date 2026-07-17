# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
