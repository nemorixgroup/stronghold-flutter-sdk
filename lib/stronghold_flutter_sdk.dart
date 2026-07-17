/// Native Flutter/Dart SDK for the SHx token ecosystem on Stellar.
///
/// A composition layer on top of `stellar_flutter_sdk`, not a fork. See
/// the Stronghold/SHx Knowledge Base (Module 06) for the full architecture
/// rationale.
library stronghold_flutter_sdk;

export 'src/core/stronghold_network.dart';
export 'src/core/stronghold_exception.dart';
export 'src/asset/shx_asset.dart';
export 'src/governance/shx_vote.dart';
export 'src/escrow/escrow_models.dart';
export 'src/escrow/escrow_client.dart';
