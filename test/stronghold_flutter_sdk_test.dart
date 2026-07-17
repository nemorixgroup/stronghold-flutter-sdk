import 'package:flutter_test/flutter_test.dart';
import 'package:stronghold_flutter_sdk/stronghold_flutter_sdk.dart';

void main() {
  group('StrongholdConstants', () {
    test('SHx issuer account matches the verified value', () {
      expect(
        StrongholdConstants.shxIssuerAccountId,
        'GDSTRSHXHGJ7ZIVRBXEYE5Q74XUVCUSEKEBR7UCHEUUEK72N7I7KJ6JH',
      );
    });

    test('SHx has 7 decimals', () {
      expect(StrongholdConstants.shxDecimals, 7);
    });
  });

  group('ShxVote', () {
    test('builds the correct ManageData entry name', () {
      const vote = ShxVote(proposalNumber: 7, votePositions: 'FOR');
      expect(vote.dataEntryName, 'SHX::PROP:7');
    });
  });
}
