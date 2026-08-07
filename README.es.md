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
  stronghold_flutter_sdk: ^0.0.3-dev
```

```yaml
flutter pub get
```

## Inicio rápido

Disponible hoy: generar una identidad y fondearla en Testnet, gratis, sin necesidad de XLM real.

```dart
import 'package:stronghold_flutter_sdk/stronghold_flutter_sdk.dart';

Future<void> main() async {
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

Trustlines de SHx, pagos y votación de gobernanza son los próximos pasos del roadmap. Ver la tabla de [Roadmap](#roadmap-v100) más arriba para el estado actual.

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
