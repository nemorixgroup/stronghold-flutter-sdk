import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';
import 'package:stronghold_flutter_sdk/src/wallet/shx_account.dart';
import 'package:stronghold_flutter_sdk/src/wallet/shx_wallet.dart';

void main() {
  group('ShxWallet.generate', () {
    test('returns a valid, unique KeyPair each time', () {
      final keyPairA = ShxWallet.generate();
      final keyPairB = ShxWallet.generate();

      expect(keyPairA.accountId, startsWith('G'));
      expect(keyPairA.accountId, isNot(equals(keyPairB.accountId)));
    });
  });

  group('ShxWallet.createPending', () {
    test('wraps a fresh keypair with pending status', () {
      final account = ShxWallet.createPending();

      expect(account.status, ShxAccountStatus.pending);
      expect(account.accountId, startsWith('G'));
    });

    test('each call produces a distinct account', () {
      final accountA = ShxWallet.createPending();
      final accountB = ShxWallet.createPending();

      expect(accountA.accountId, isNot(equals(accountB.accountId)));
    });
  });

  group('ShxAccount.copyWith', () {
    test('changes status while keeping the same keypair', () {
      final keyPair = KeyPair.random();
      final account = ShxAccount(
        keyPair: keyPair,
        status: ShxAccountStatus.pending,
      );

      final funded = account.copyWith(status: ShxAccountStatus.funded);

      expect(funded.status, ShxAccountStatus.funded);
      expect(funded.accountId, account.accountId);
    });

    test('with no status argument keeps the original status', () {
      final keyPair = KeyPair.random();
      final account = ShxAccount(
        keyPair: keyPair,
        status: ShxAccountStatus.shxReady,
      );

      final copy = account.copyWith();

      expect(copy.status, ShxAccountStatus.shxReady);
    });
  });
}
