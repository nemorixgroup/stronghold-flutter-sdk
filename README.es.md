[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Dart](https://img.shields.io/badge/Dart-3.x-blue.svg)](https://dart.dev)
[![Flutter](https://img.shields.io/badge/Flutter-3.x-blue.svg)](https://flutter.dev)
[![CI](https://github.com/nemorixgroup/stronghold-flutter-sdk/actions/workflows/ci.yml/badge.svg)](https://github.com/nemorixgroup/stronghold-flutter-sdk/actions)
[![Status](https://img.shields.io/badge/Status-Phase%202%20In%20Progress-red.svg)](https://github.com/nemorixgroup/stronghold-flutter-sdk/blob/main)

[English](https://github.com/nemorixgroup/stronghold-flutter-sdk/blob/main/README.md) | **Español**

# stronghold_flutter_sdk

SDK nativo de Flutter/Dart para el ecosistema del token SHx sobre Stellar.
Capa de composición sobre `stellar_flutter_sdk`, no es un fork · MIT · pub.dev

> **Estado: desarrollo temprano.** La API todavía no es estable.
> Fase actual: Fase 2, operaciones del asset SHx.

SHx no tiene blockchain propia: es un asset emitido sobre Stellar. Este SDK agrega operaciones específicas de SHx, votación de gobernanza basada en `ManageData`, y bindings para el contrato de escrow on-chain de Stronghold, sobre la base de `stellar_flutter_sdk`, activamente mantenido.

## Roadmap (v1.0.0)

| Fase | Enfoque | Versión | Estado |
|-------|----------------------------------------------------|-------------|----------------|
| 1 | Arquitectura y configuración base | `0.0.1-dev` | ✅ Completa |
| 2 | Operaciones del asset SHx (trustline, pago, path payment) | `0.1.0-dev` | 🔄 En progreso |
| 3 | Gobernanza (votación vía ManageData) | `0.2.0-dev` | ⏳ Planeada |
| 4 | Cliente del contrato de escrow (lock/unlock de 60B SHx) | `0.3.0-dev` | ⏳ Planeada |
| 5 | Seguimiento de estado del bridge | `0.4.0-dev` | ⏳ Planeada |
| 6 | Documentación, testing y pub.dev v1.0 | `1.0.0` | ⏳ Planeada |

Roadmap completo con tareas y milestones: ver [ROADMAP.md](ROADMAP.md).

## Documentación y Knowledge Base

Este SDK se construye sobre el [Stronghold/SHx Knowledge Base](https://github.com/nemorixgroup/Stronghold-Knowledge-Base), que cubre el token SHx, la mecánica de gobernanza, el contrato de escrow y StrongholdNET. Lectura recomendada antes de meterse en los detalles internos del SDK.

Cada decisión de implementación detrás de este SDK, elección de librerías, estándares de codificación, verificación contra especificaciones oficiales, está documentada en [docs-sdk/](https://github.com/nemorixgroup/Stronghold-Knowledge-Base/tree/main/docs-sdk).

## Instalación

```yaml
# pubspec.yaml
dependencies:
  stronghold_flutter_sdk: ^0.0.6-dev
```

```bash
flutter pub get
```

## Requisitos

- Flutter 3.32.0 o superior (Dart 3.8.0 o superior)
- Android, iOS o web

Este paquete solo funciona dentro de una app Flutter. Se apoya en `stellar_flutter_sdk`, que a su vez depende de Flutter, por lo que no se puede usar desde un programa Dart puro (una herramienta de línea de comandos o un servidor Dart). Por la misma razón, los archivos de [`example/`](example/README.md) no se pueden ejecutar con `dart run`; están pensados para copiarse a una app Flutter.

Este paquete reexporta `KeyPair`, `Network` y `StellarSDK` de `stellar_flutter_sdk`. Son los tipos que se pasan a sus métodos principales, así que con un único import de `package:stronghold_flutter_sdk/stronghold_flutter_sdk.dart` alcanza para los fragmentos de más abajo. Para cualquier otra cosa de Stellar, por ejemplo armar tus propias transacciones con los builders de `ShxTrustline` o `ShxPayment`, agregá `stellar_flutter_sdk` a tu propio `pubspec.yaml` e importalo. Si otro paquete que usás define su propio `KeyPair`, ocultá o poné un prefijo a uno de los dos para evitar el choque de nombres.

## Inicio rápido

Disponible hoy: onboarding de cuentas (identidad, fondeo en Testnet y Mainnet, trustline de SHx, o todo en una sola llamada) y consulta de balances. Los pasos que solo funcionan en Mainnet están marcados. Los fragmentos se ejecutan dentro de una función async de tu app Flutter, por ejemplo desde el handler de un botón. Hay más ejemplos en [`example/`](example/README.md).

Generar una identidad y fondearla en Testnet, gratis y sin XLM real:

```dart
import 'package:stronghold_flutter_sdk/stronghold_flutter_sdk.dart';

Future<void> onboardOnTestnet() async {
  // Genera una nueva identidad y la fondea en Testnet vía Friendbot.
  final account = await ShxWallet.fundOnTestnet(ShxWallet.createPending());

  print('Nueva cuenta Testnet: ${account.accountId}');
  print('Estado: ${account.status}'); // ShxAccountStatus.funded
}
```

Crear y fondear una cuenta en Mainnet sigue el mismo patrón, pero requiere una fuente de fondeo con XLM real:

```dart
final account = await ShxWallet.createAndFund(
  account: ShxWallet.createPending(),
  sdk: StellarSDK.PUBLIC,
  network: Network.PUBLIC,
  fundingSourceKeyPair: myFundingKeyPair,
  startingBalance: '5',
);
```

Una vez fondeada, una cuenta necesita una trustline antes de poder tener SHx (solo Mainnet, ya que el issuer real de SHx no existe en Testnet):

```dart
final ready = await ShxWallet.establishShxTrustline(
  account: myFundedAccount,
  sdk: StellarSDK.PUBLIC,
  network: Network.PUBLIC,
);
// ready.status == ShxAccountStatus.shxReady
```

Los dos pasos también pueden ocurrir en una sola transacción atómica, de modo que la cuenta nunca queda a medio configurar (solo Mainnet). Las dos claves, la de la fuente de fondeo y la de la cuenta nueva, tienen que firmar en el mismo lugar; si viven en dispositivos distintos, usá los dos pasos separados de arriba. Guardá el secret seed de la cuenta nueva antes de llamarlo: una vez que la cuenta tiene fondos, perder la clave significa perderlos.

```dart
final pending = ShxWallet.createPending();
// Guardá pending.keyPair.secretSeed en un lugar seguro ANTES de esta llamada.

final ready = await ShxWallet.bootstrapForShx(
  account: pending,
  sdk: StellarSDK.PUBLIC,
  network: Network.PUBLIC,
  fundingSourceKeyPair: myFundingKeyPair,
  startingBalance: '2', // al menos ShxWallet.minimumBootstrapBalance (1.5 XLM)
);
// ready.status == ShxAccountStatus.shxReady
```

Una vez que una cuenta está `shxReady`, podés consultar sus balances:

```dart
final xlm = await ShxBalance.getXlmBalance(
  accountId: myAccount.accountId,
  sdk: StellarSDK.PUBLIC,
);

final shx = await ShxBalance.getShxBalance(
  accountId: myAccount.accountId,
  sdk: StellarSDK.PUBLIC,
);
// shx es '0' si la cuenta todavía no tiene trustline de SHx
```

Pagos de SHx, path payments y votación de gobernanza son los próximos pasos del roadmap. Ver la tabla de [Roadmap](#roadmap-v100) más arriba para el estado actual.

## Redes

| Red | Horizon URL | Soroban RPC |
|---|---|---|
| Mainnet | `https://horizon.stellar.org` | Sin RPC público oficial, hay que traer un proveedor propio |
| Testnet | `https://horizon-testnet.stellar.org` | `https://soroban-testnet.stellar.org` |

## Contribuciones

El SDK todavía no está listo para contribuciones externas.
Seguí este repositorio para novedades; las contribuciones van a
estar habilitadas a partir de v1.0.0.

Ver [CONTRIBUTING.md](https://github.com/nemorixgroup/stronghold-flutter-sdk/blob/main/CONTRIBUTING.md) para las guías futuras.

## Licencia

Licenciado bajo [MIT](https://github.com/nemorixgroup/stronghold-flutter-sdk/blob/main/LICENSE).

## Para desarrolladores de LATAM

Este SDK se desarrolla pensando en soporte nativo para la región:

- Documentación bilingüe (inglés/español) desde el primer módulo.
- Parte del ecosistema de SDKs de Nemorix Group para infraestructura financiera en LATAM (Hedera, Avalanche, XRPL, Stellar, Stronghold).
- Desarrollado por [Nemorix Group](https://nemorixpay.com), Ohio, EE.UU.

Seguinos para novedades: **<sdks@nemorixpay.com>**

## Apoyá este proyecto

Si este SDK te resulta útil o a tu equipo, considerá apoyar su desarrollo. Cada contribución ayuda a cubrir infraestructura, documentación, y el tiempo invertido en construir y mantener esta herramienta open source para la comunidad SHx y Flutter. ¡Gracias!

[![Buy Me a Coffee](https://img.shields.io/badge/Buy%20Me%20A%20Coffee-Support-FFDD00?logo=buy-me-a-coffee&logoColor=black)](https://buymeacoffee.com/nemorixgroupllc)
[![Sponsor](https://img.shields.io/badge/Sponsor-GitHub-EA4AAA?logo=github-sponsors&logoColor=white)](https://github.com/sponsors/nemorixgroup)
[![Ko-fi](https://img.shields.io/badge/Ko--fi-Support-FF5E5B?logo=ko-fi&logoColor=white)](https://ko-fi.com/nemorixgroupllc)

---

Construido por [Nemorix Group](https://nemorixpay.com) · MIT
