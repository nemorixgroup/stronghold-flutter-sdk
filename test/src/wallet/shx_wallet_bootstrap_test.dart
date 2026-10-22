import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';
import 'package:stronghold_flutter_sdk/src/core/stronghold_exception.dart';
import 'package:stronghold_flutter_sdk/src/wallet/shx_account.dart';
import 'package:stronghold_flutter_sdk/src/wallet/shx_wallet.dart';

// bootstrapForShx validates its input before touching the network, so these
// tests pass a real StellarSDK instance but never trigger a request: every
// case below must be rejected first.
Future<ShxAccount> _bootstrap({
  required ShxAccount account,
  required String startingBalance,
}) {
  return ShxWallet.bootstrapForShx(
    account: account,
    sdk: StellarSDK.TESTNET,
    network: Network.TESTNET,
    fundingSourceKeyPair: KeyPair.random(),
    startingBalance: startingBalance,
  );
}

Matcher _strongholdErrorContaining(String text) {
  return throwsA(
    isA<StrongholdException>().having(
      (e) => e.message,
      'message',
      contains(text),
    ),
  );
}

void main() {
  group('ShxWallet.minimumBootstrapBalance', () {
    test('is 1.5 XLM (two base reserves plus one trustline)', () {
      expect(ShxWallet.minimumBootstrapBalance, '1.5');
    });
  });

  group('ShxWallet.bootstrapForShx account status', () {
    for (final status in ShxAccountStatus.values) {
      if (status == ShxAccountStatus.pending) continue;

      test('rejects an account that is already ${status.name}', () async {
        final account = ShxAccount(keyPair: KeyPair.random(), status: status);

        await expectLater(
          _bootstrap(account: account, startingBalance: '2'),
          _strongholdErrorContaining('pending'),
        );
      });
    }
  });

  group('ShxWallet.bootstrapForShx startingBalance', () {
    test('rejects a balance just below the minimum', () async {
      await expectLater(
        _bootstrap(
          account: ShxWallet.createPending(),
          startingBalance: '1.4999999',
        ),
        _strongholdErrorContaining('at least'),
      );
    });

    const invalidAmounts = <String>[
      '',
      'abc',
      'NaN',
      'Infinity',
      '-Infinity',
      '-2',
      '0',
    ];

    for (final value in invalidAmounts) {
      test('rejects "$value" as a startingBalance', () async {
        await expectLater(
          _bootstrap(
            account: ShxWallet.createPending(),
            startingBalance: value,
          ),
          _strongholdErrorContaining('startingBalance'),
        );
      });
    }
  });
}
