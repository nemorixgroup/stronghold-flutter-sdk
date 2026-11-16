@Tags(['integration'])
library;

// Integration tests: these hit Stellar Testnet for real (Friendbot and
// Horizon). Kept separate from the unit tests in shx_payment_test.dart, per
// this project's convention.
//
// The real SHx issuer only exists on Mainnet, so no account on Testnet can
// hold SHx. That is why these tests stop at the checks made before
// submitting: they show which failures are reported, that none of them sends
// anything, and that valid inputs get past validation.

import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';
import 'package:stronghold_flutter_sdk/src/asset/shx_asset.dart';
import 'package:stronghold_flutter_sdk/src/core/stronghold_exception.dart';
import 'package:stronghold_flutter_sdk/src/wallet/shx_account.dart';
import 'package:stronghold_flutter_sdk/src/wallet/shx_balance.dart';
import 'package:stronghold_flutter_sdk/src/wallet/shx_wallet.dart';

// On Testnet an account cannot really be shxReady, so the status is set by
// hand to get past the first check of ShxPayment.send.
ShxAccount _markedShxReady(ShxAccount account) {
  return account.copyWith(status: ShxAccountStatus.shxReady);
}

// The right code, and no transaction hash: nothing was ever submitted.
Matcher _rejectedWith(ShxPaymentErrorCode code) {
  return throwsA(
    isA<ShxPaymentException>()
        .having((e) => e.code, 'code', code)
        .having((e) => e.transactionHash, 'transactionHash', isNull),
  );
}

// A valid input gets past validation and reaches the destination lookup. A
// destination that was never funded does not exist, so the payment stops at
// destinationNotFound instead of invalidAmount or invalidMemo. The source is
// never loaded, because the destination is checked first.
Future<void> _expectGetsPastValidation({
  required String amount,
  String? memo,
}) {
  return expectLater(
    ShxPayment.send(
      source: _markedShxReady(ShxWallet.createPending()),
      destinationAccountId: KeyPair.random().accountId,
      amount: amount,
      sdk: StellarSDK.TESTNET,
      network: Network.TESTNET,
      memo: memo,
    ),
    _rejectedWith(ShxPaymentErrorCode.destinationNotFound),
  );
}

void main() {
  group('ShxPayment.send on Testnet', () {
    test('reports a destination that does not exist', () async {
      await _expectGetsPastValidation(amount: '10');
    });

    test(
      'reports a destination without the SHx trustline, and sends nothing',
      () async {
        final source = _markedShxReady(
          await ShxWallet.fundOnTestnet(ShxWallet.createPending()),
        );
        final destination = await ShxWallet.fundOnTestnet(
          ShxWallet.createPending(),
        );
        final sequenceBefore = (await StellarSDK.TESTNET.accounts.account(
          source.accountId,
        )).sequenceNumber;
        final xlmBefore = await ShxBalance.getXlmBalance(
          accountId: source.accountId,
          sdk: StellarSDK.TESTNET,
        );

        await expectLater(
          ShxPayment.send(
            source: source,
            destinationAccountId: destination.accountId,
            amount: '10',
            sdk: StellarSDK.TESTNET,
            network: Network.TESTNET,
          ),
          _rejectedWith(ShxPaymentErrorCode.destinationNoTrustline),
        );

        // A submitted transaction, even a failed one, would have used a
        // sequence number and charged a fee.
        final sequenceAfter = (await StellarSDK.TESTNET.accounts.account(
          source.accountId,
        )).sequenceNumber;
        final xlmAfter = await ShxBalance.getXlmBalance(
          accountId: source.accountId,
          sdk: StellarSDK.TESTNET,
        );
        expect(sequenceAfter, sequenceBefore);
        expect(xlmAfter, xlmBefore);
      },
    );

    const validAmounts = <String>[
      // One stroop, the smallest amount.
      '0.0000001',
      '1',
      '10.5',
      '1234567.1234567',
      // The largest amount Stellar can represent.
      '922337203685.4775807',
    ];

    for (final amount in validAmounts) {
      test('accepts the amount "$amount"', () async {
        await _expectGetsPastValidation(amount: amount);
      });
    }

    final validMemos = <String, String>{
      'a 1-byte memo': '1',
      'a memo of 28 ASCII bytes': 'a' * 28,
      'a memo of 14 two-byte characters (28 bytes)': '\u00F1' * 14,
      'a memo of 7 emoji (28 bytes)': '\u{1F680}' * 7,
    };

    for (final entry in validMemos.entries) {
      test('accepts ${entry.key}', () async {
        await _expectGetsPastValidation(amount: '1', memo: entry.value);
      });
    }

    test(
      'sends SHx and returns the transaction hash (happy path)',
      () {},
      skip:
          'Needs a funded Mainnet account holding SHx: the real SHx issuer '
          'only exists on Mainnet. See docs-sdk/phase-2/shx-trustline/.',
    );
  });

  group('transaction hash', () {
    // ShxPayment.send computes the hash before submitting and returns it.
    // This checks that recipe (build, sign, hash) against what Horizon
    // reports, with an XLM payment that Testnet can complete.
    test('the locally computed hash matches the one Horizon reports', () async {
      final sender = await ShxWallet.fundOnTestnet(ShxWallet.createPending());
      final receiver = await ShxWallet.fundOnTestnet(
        ShxWallet.createPending(),
      );
      final senderAccount = await StellarSDK.TESTNET.accounts.account(
        sender.accountId,
      );

      final transaction =
          TransactionBuilder(senderAccount)
              .addOperation(
                PaymentOperationBuilder(
                  receiver.accountId,
                  Asset.NATIVE,
                  '1',
                ).build(),
              )
              .build()
            ..sign(sender.keyPair, Network.TESTNET);
      final localHash = Util.bytesToHex(transaction.hash(Network.TESTNET));

      final response = await StellarSDK.TESTNET.submitTransaction(transaction);

      expect(response.success, isTrue);
      expect(response.hash, localHash);
    });
  });
}
