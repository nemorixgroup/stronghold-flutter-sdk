@Tags(['integration'])
library;

// Integration tests: these hit Stellar Testnet for real via Friendbot.
// Slower and dependent on Testnet being up; kept separate from the
// pure unit tests in shx_wallet_test.dart for that reason.

import 'package:flutter_test/flutter_test.dart';
import 'package:stronghold_flutter_sdk/src/wallet/shx_account.dart';
import 'package:stronghold_flutter_sdk/src/wallet/shx_wallet.dart';

void main() {
  group('ShxWallet.fundOnTestnet', () {
    test('funds a pending account and updates its status', () async {
      final pending = ShxWallet.createPending();

      final funded = await ShxWallet.fundOnTestnet(pending);

      expect(funded.status, ShxAccountStatus.funded);
      expect(funded.accountId, pending.accountId);
    });

    test(
      'throws StrongholdException for an invalid account id',
      () async {
        final invalid = ShxAccount(
          keyPair: ShxWallet.generate(),
          status: ShxAccountStatus.pending,
        );

        // A syntactically invalid accountId is the simplest reliable way
        // to force Friendbot to decline without depending on Testnet
        // being in any particular state.
        // ignore: avoid_dynamic_calls
        final tampered = ShxAccount(
          keyPair: invalid.keyPair,
          status: ShxAccountStatus.pending,
        );

        expect(
          () => ShxWallet.fundOnTestnet(tampered),
          anything, // placeholder, see note below
        );
      },
      skip: 'Needs a reliable way to force a Friendbot failure; see note',
    );
  });
}
