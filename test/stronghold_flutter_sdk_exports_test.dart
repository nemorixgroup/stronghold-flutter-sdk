// This file deliberately does NOT import stellar_flutter_sdk. It must compile
// using only what the package barrel exposes, so it fails if one of the
// re-exports is ever removed.

import 'package:flutter_test/flutter_test.dart';
import 'package:stronghold_flutter_sdk/stronghold_flutter_sdk.dart';

void main() {
  group('barrel re-exports from stellar_flutter_sdk', () {
    test('exposes KeyPair', () {
      expect(ShxWallet.generate(), isA<KeyPair>());
    });

    test('exposes Network', () {
      expect(Network.TESTNET, isA<Network>());
    });

    test('exposes StellarSDK', () {
      expect(StellarSDK.TESTNET, isA<StellarSDK>());
    });
  });
}
