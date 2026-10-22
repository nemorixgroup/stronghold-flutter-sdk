# stronghold_flutter_sdk example

Examples for `stronghold_flutter_sdk`, added incrementally as each phase of the SHx roadmap lands.

## How to use these examples

These files are illustrative. `stronghold_flutter_sdk` builds on `stellar_flutter_sdk`, which depends on Flutter, so the examples cannot be run with `dart run`. Copy the function you need into a Flutter app and call it from there, for example from a button handler. Each file defines one function named `<topic>Example()` and no `main()`.

Examples marked "Mainnet only" use the real SHx issuer, which does not exist on Testnet, and need an account holding real XLM.

## Available examples

| Phase | Example | Network | Demonstrates |
|---|---|---|---|
| 2 | [`account_onboarding_example.dart`](phase2/account_onboarding_example.dart) | Testnet | Generate an identity and fund it |
| 2 | [`shx_trustline_example.dart`](phase2/shx_trustline_example.dart) | Mainnet only | Open a SHx trustline |
| 2 | [`shx_balance_example.dart`](phase2/shx_balance_example.dart) | Testnet | Read XLM and SHx balances |
| 2 | [`shx_bootstrap_example.dart`](phase2/shx_bootstrap_example.dart) | Mainnet only | Create, fund, and open a SHx trustline in one atomic transaction |

## Planned examples

| Phase | Example | Status |
|---|---|---|
| 2 | `mainnet_account_creation_example.dart`, create and fund an account on Mainnet | ⏳ Pending |
| 2 | `payment_example.dart`, send a SHx payment | ⏳ Pending |
| 2 | `path_payment_example.dart`, cross-asset SHx conversion | ⏳ Pending |
| 3 | `governance_vote_example.dart`, cast and read back a governance vote | ⏳ Pending |
| 4 | `escrow_lock_unlock_example.dart`, lock, read, and unlock a SHx escrow | ⏳ Pending |
| 5 | `bridge_status_tracking_example.dart`, check the status of a cross-chain SHx transfer | ⏳ Pending |
