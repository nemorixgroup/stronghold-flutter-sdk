# stronghold_flutter_sdk

Native Flutter/Dart SDK for the SHx token ecosystem on Stellar: SHx asset operations (trustlines, payments), ManageData-based governance voting, and bindings for Stronghold's on-chain 60B SHx escrow contract.

> SHx does not have its own blockchain. It is an asset issued on Stellar. This SDK is a composition layer on top of [`stellar_flutter_sdk`](https://github.com/Soneso/stellar_flutter_sdk) (Soneso, MIT), not a fork. See the [Stronghold/SHx Knowledge Base](https://github.com/nemorixgroup/Stronghold-Knowledge-Base) for the full technical background and architecture rationale.

## Status

Phase 1 (architecture scaffold), in progress. Method signatures for asset and governance operations are defined; escrow contract invocation and the read-path for votes and escrow lookups are pending implementation and testing against Testnet.

| Module | Status |
|---|---|
| Core network config / constants | Done |
| SHx asset (trustline, payment) | Scaffolded, pending test coverage |
| Governance (ManageData voting) | Scaffolded, pending test coverage |
| Escrow contract client | Scaffolded, invocation logic pending (Phase 2) |
| Path payments | Pending |
| Example app | Pending |

## Why depend on stellar_flutter_sdk instead of forking it

Forking would mean re-doing maintenance that Soneso already does, funded by the Stellar Public Goods Program: protocol updates, XDR changes, Soroban RPC changes. This SDK depends on it as a normal pub.dev package and adds only what is SHx-specific: asset constants, trustline/payment helpers, the governance voting format, and the escrow contract bindings. See Module 06 of the Knowledge Base for the full reasoning.

## Verified on-chain facts this SDK is built against

- SHx asset: `SHX` issued by `GDSTRSHXHGJ7ZIVRBXEYE5Q74XUVCUSEKEBR7UCHEUUEK72N7I7KJ6JH`, 7 decimals.
- Governance voting uses classic `ManageData` operations, not a Soroban contract.
- The documented "SHx Soroban Contract ID" (`CCKCKCPHYVXQD4NECBFJTFSCU2AMSJGCNG4O6K4JVRE2BLPR7WNDBQIQ`) is the auto-generated Stellar Asset Contract (SAC), a standard SEP-41 wrapper, not custom governance logic.
- The 60B SHx escrow contract (`CCA5HAZCPEYXD7JBKAJCVUZUXAK7V5ZFU3QMJO33OJH2OHL3OGLS2P7M`) exposes `lock`, `unlock`, and `extend_ttl`; its spec was pulled directly via `stellar contract inspect` against Mainnet.

## License

MIT
