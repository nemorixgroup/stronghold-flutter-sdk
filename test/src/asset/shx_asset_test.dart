import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';
import 'package:stronghold_flutter_sdk/src/asset/shx_asset.dart';
import 'package:stronghold_flutter_sdk/src/core/stronghold_network.dart';

void main() {
  group('ShxTrustline.buildEstablishOperation', () {
    test('targets the real SHx asset code and issuer', () {
      final operation = ShxTrustline.buildEstablishOperation().build();

      final asset = operation.asset;
      expect(asset, isA<AssetTypeCreditAlphaNum4>());
      final creditAsset = asset as AssetTypeCreditAlphaNum4;
      expect(creditAsset.code, StrongholdConstants.shxAssetCode);
      expect(creditAsset.issuerId, StrongholdConstants.shxIssuerAccountId);
    });

    test('defaults to the SDK maximum limit when none is given', () {
      final operation = ShxTrustline.buildEstablishOperation().build();

      expect(operation.limit, ChangeTrustOperationBuilder.MAX_LIMIT);
    });

    test('accepts a custom limit', () {
      final operation = ShxTrustline.buildEstablishOperation(
        limit: '1000',
      ).build();

      expect(operation.limit, '1000');
    });
  });

  group('ShxTrustline.buildRemoveOperation', () {
    test('sets the limit to zero', () {
      final operation = ShxTrustline.buildRemoveOperation().build();

      expect(operation.limit, '0');
    });
  });
}
