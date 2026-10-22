[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Dart](https://img.shields.io/badge/Dart-3.x-blue.svg)](https://dart.dev)
[![Flutter](https://img.shields.io/badge/Flutter-3.x-blue.svg)](https://flutter.dev)
[![CI](https://github.com/nemorixgroup/stronghold-flutter-sdk/actions/workflows/ci.yml/badge.svg)](https://github.com/nemorixgroup/stronghold-flutter-sdk/actions)
[![Status](https://img.shields.io/badge/Status-Phase%202%20In%20Progress-red.svg)](https://github.com/nemorixgroup/stronghold-flutter-sdk/blob/main)

**English** | [Español](https://github.com/nemorixgroup/stronghold-flutter-sdk/blob/main/README.es.md)

# stronghold_flutter_sdk

Native Flutter/Dart SDK for the SHx token ecosystem on Stellar.
Composition layer over `stellar_flutter_sdk`, not a fork · MIT · pub.dev

> **Status: Early Development.** API is not stable.
> Current phase: Phase 2 - SHx asset operations.

SHx does not have its own blockchain: it is an asset issued on Stellar. This
SDK adds SHx-specific asset operations, ManageData-based governance voting,
and bindings for Stronghold's on-chain escrow contract, on top of the
actively-maintained `stellar_flutter_sdk`.

## Roadmap (v1.0.0)

| Phase | Focus                                             | Version     | Status         |
|-------|----------------------------------------------------|-------------|----------------|
| 1     | Architecture & core setup                          | `0.0.1-dev` | ✅ Done |
| 2     | SHx asset operations (trustline, payment, path payment) | `0.1.0-dev` | 🔄 In progress |
| 3     | Governance (ManageData voting)                     | `0.2.0-dev` | ⏳ Planned     |
| 4     | Escrow contract client (60B SHx lock/unlock)        | `0.3.0-dev` | ⏳ Planned     |
| 5     | Bridge Status & Tracking        | `0.4.0-dev` | ⏳ Planned     |
| 6     | Docs, testing & pub.dev v1.0                        | `1.0.0`     | ⏳ Planned     |

Full roadmap with tasks and milestones: see [ROADMAP.md](ROADMAP.md).

## Documentation & Knowledge Base

This SDK is built on top of the [Stronghold/SHx Knowledge Base](https://github.com/nemorixgroup/Stronghold-Knowledge-Base), covering the SHx token, governance mechanics, the escrow contract, and StrongholdNET. Recommended reading before diving into the SDK internals.

Every implementation decision behind this SDK - library choices,
encoding standards, verification against official specs - is
documented in [docs-sdk/](https://github.com/nemorixgroup/Stronghold-Knowledge-Base/tree/main/docs-sdk).

## Installation

```yaml
# pubspec.yaml
dependencies:
  stronghold_flutter_sdk: ^0.0.6-dev
```

```bash
flutter pub get
```

## Requirements

- Flutter 3.32.0 or newer (Dart 3.8.0 or newer)
- Android, iOS, or web

This package only works inside a Flutter app. It builds on `stellar_flutter_sdk`, which itself depends on Flutter, so it cannot be used from a pure Dart program (a command-line tool or a Dart server). For the same reason, the files under [`example/`](example/README.md) cannot be run with `dart run`; they are meant to be copied into a Flutter app.

This package re-exports `KeyPair`, `Network`, and `StellarSDK` from `stellar_flutter_sdk`. They are the types you pass to its main methods, so a single import of `package:stronghold_flutter_sdk/stronghold_flutter_sdk.dart` is enough for the snippets below. For anything else from Stellar, for example building your own transactions around the operation builders in `ShxTrustline` or `ShxPayment`, add `stellar_flutter_sdk` to your own `pubspec.yaml` and import it. If another package you use defines its own `KeyPair`, hide or prefix one of the two to avoid a name clash.

## Quick Start

Available today: account onboarding (identity, funding on Testnet and Mainnet, SHx trustline, or all of it in one call) and balance queries. Steps that only work on Mainnet are marked. The snippets run inside an async function of your Flutter app, for example a button handler. More examples live in [`example/`](example/README.md).

Generate an identity and fund it on Testnet, free and with no real XLM:

```dart
import 'package:stronghold_flutter_sdk/stronghold_flutter_sdk.dart';

Future<void> onboardOnTestnet() async {
  // Generate a new identity and fund it on Testnet via Friendbot.
  final account = await ShxWallet.fundOnTestnet(ShxWallet.createPending());

  print('New Testnet account: ${account.accountId}');
  print('Status: ${account.status}'); // ShxAccountStatus.funded
}
```

Creating and funding an account on Mainnet follows the same pattern, but requires a funding source with real XLM:

```dart
final account = await ShxWallet.createAndFund(
  account: ShxWallet.createPending(),
  sdk: StellarSDK.PUBLIC,
  network: Network.PUBLIC,
  fundingSourceKeyPair: myFundingKeyPair,
  startingBalance: '5',
);
```

Once funded, an account needs a trustline before it can hold SHx (Mainnet only, since the real SHx issuer does not exist on Testnet):

```dart
final ready = await ShxWallet.establishShxTrustline(
  account: myFundedAccount,
  sdk: StellarSDK.PUBLIC,
  network: Network.PUBLIC,
);
// ready.status == ShxAccountStatus.shxReady
```

Both steps can also happen in one atomic transaction, so the account is never left half set up (Mainnet only). Both secrets, the funding source and the new account, must sign in the same place; if they live on different devices, use the two separate steps above. Save the new account's secret seed before calling it: once the account holds funds, losing the key means losing them.

```dart
final pending = ShxWallet.createPending();
// Persist pending.keyPair.secretSeed somewhere safe BEFORE this call.

final ready = await ShxWallet.bootstrapForShx(
  account: pending,
  sdk: StellarSDK.PUBLIC,
  network: Network.PUBLIC,
  fundingSourceKeyPair: myFundingKeyPair,
  startingBalance: '2', // at least ShxWallet.minimumBootstrapBalance (1.5 XLM)
);
// ready.status == ShxAccountStatus.shxReady
```

Once an account is `shxReady`, check its balances:

```dart
final xlm = await ShxBalance.getXlmBalance(
  accountId: myAccount.accountId,
  sdk: StellarSDK.PUBLIC,
);

final shx = await ShxBalance.getShxBalance(
  accountId: myAccount.accountId,
  sdk: StellarSDK.PUBLIC,
);
// shx is '0' if the account has no SHx trustline yet
```

SHx payments, path payments, and governance voting are next on the roadmap. See the [Roadmap](#roadmap-v100) table above for current status.

## Networks

| Network | Horizon URL | Soroban RPC |
|---|---|---|
| Mainnet | `https://horizon.stellar.org` | No official public RPC, bring your own provider |
| Testnet | `https://horizon-testnet.stellar.org` | `https://soroban-testnet.stellar.org` |

## Contributing

The SDK is not ready for external contributions yet.
Follow this repository for updates; contributions will
be welcome starting with v1.0.0.

See [CONTRIBUTING.md](https://github.com/nemorixgroup/stronghold-flutter-sdk/blob/main/CONTRIBUTING.md) for future guidelines.

## License

Licensed under [MIT](https://github.com/nemorixgroup/stronghold-flutter-sdk/blob/main/LICENSE).

## For LATAM developers

This SDK is being developed with native support for the region in mind:

- Bilingual documentation (English / Spanish) from the very first module.
- Part of Nemorix Group's SDK ecosystem for financial infrastructure
in LATAM (Hedera, Avalanche, XRPL, Stellar, Stronghold).
- Developed by [Nemorix Group](https://nemorixpay.com), Ohio, USA.

Follow us for updates: **<sdks@nemorixpay.com>**

## Support This Project

If this SDK is useful to you or your team, consider supporting its
development. Every contribution helps cover infrastructure,
documentation, and the time invested in building and maintaining this
open source tool for the SHx and Flutter community. Thank you!

[![Buy Me a Coffee](https://img.shields.io/badge/Buy%20Me%20A%20Coffee-Support-FFDD00?logo=buy-me-a-coffee&logoColor=black)](https://buymeacoffee.com/nemorixgroupllc)
[![Sponsor](https://img.shields.io/badge/Sponsor-GitHub-EA4AAA?logo=github-sponsors&logoColor=white)](https://github.com/sponsors/nemorixgroup)
[![Ko-fi](https://img.shields.io/badge/Ko--fi-Support-FF5E5B?logo=ko-fi&logoColor=white)](https://ko-fi.com/nemorixgroupllc)

---

Built by [Nemorix Group](https://nemorixpay.com) · MIT