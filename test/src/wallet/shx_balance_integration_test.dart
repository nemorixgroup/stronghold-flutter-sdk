@Tags(['integration'])
library;

// Integration tests: these hit Stellar Testnet for real via Friendbot
// and Horizon reads. Kept separate from unit tests per this project's
// convention (see shx_wallet_integration_test.dart).

import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';
import 'package:stronghold_flutter_sdk/src/core/stronghold_exception.dart';
import 'package:stronghold_flutter_sdk/src/wallet/shx_balance.dart';
import 'package:stronghold_flutter_sdk/src/wallet/shx_wallet.dart';

void main() {
  group('ShxBalance.getXlmBalance', () {
    test(
      'returns a positive XLM balance for a freshly funded account',
      () async {
        final funded = await ShxWallet.fundOnTestnet(ShxWallet.createPending());

        final balance = await ShxBalance.getXlmBalance(
          accountId: funded.accountId,
          sdk: StellarSDK.TESTNET,
        );

        expect(double.parse(balance), greaterThan(0));
      },
    );

    test('throws StrongholdException for a nonexistent account', () async {
      final neverFunded = ShxWallet.generate();

      expect(
        () => ShxBalance.getXlmBalance(
          accountId: neverFunded.accountId,
          sdk: StellarSDK.TESTNET,
        ),
        throwsA(isA<StrongholdException>()),
      );
    });
  });

  group('ShxBalance.getShxBalance', () {
    test(
      'returns zero for an account with no SHx trustline',
      () async {
        final funded = await ShxWallet.fundOnTestnet(ShxWallet.createPending());

        final balance = await ShxBalance.getShxBalance(
          accountId: funded.accountId,
          sdk: StellarSDK.TESTNET,
        );

        expect(balance, '0');
      },
      skip:
          'Needs a Mainnet account with a real SHx balance to verify '
          'the non-zero path; see the Testnet/Mainnet asset boundary '
          'finding in docs-sdk/phase-2/shx-trustline/.',
    );
  });
}
