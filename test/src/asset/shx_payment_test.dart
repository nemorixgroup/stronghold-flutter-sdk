import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';
import 'package:stronghold_flutter_sdk/src/asset/shx_asset.dart';
import 'package:stronghold_flutter_sdk/src/core/stronghold_exception.dart';
import 'package:stronghold_flutter_sdk/src/core/stronghold_network.dart';
import 'package:stronghold_flutter_sdk/src/wallet/shx_account.dart';

// ShxPayment.send validates its input before any network call, so these tests
// pass a real StellarSDK instance but never trigger a request: every case
// below must be rejected first. If a validation ever broke, the call would
// reach Testnet and the failure would look like a network error instead of an
// assertion.

ShxAccount _readyAccount() {
  return ShxAccount(
    keyPair: KeyPair.random(),
    status: ShxAccountStatus.shxReady,
  );
}

Future<String> _send({
  required ShxAccount source,
  required String destination,
  String amount = '10',
  String? memo,
}) {
  return ShxPayment.send(
    source: source,
    destinationAccountId: destination,
    amount: amount,
    sdk: StellarSDK.TESTNET,
    network: Network.TESTNET,
    memo: memo,
  );
}

// A payment rejected before the network: the right code, and no transaction
// hash, because no transaction was ever built.
Matcher _rejectedBeforeSending(ShxPaymentErrorCode code) {
  return throwsA(
    isA<ShxPaymentException>()
        .having((e) => e.code, 'code', code)
        .having((e) => e.transactionHash, 'transactionHash', isNull),
  );
}

// Changing the last character of an address changes its checksum, and a
// CRC-16 always detects an error that small.
String _withCorruptedChecksum(String accountId) {
  final last = accountId[accountId.length - 1];
  final replacement = last == 'A' ? 'B' : 'A';
  return accountId.substring(0, accountId.length - 1) + replacement;
}

void main() {
  final validDestination = KeyPair.random().accountId;

  group('ShxPayment.maxMemoBytes', () {
    test('is 28, the size of a Stellar text memo', () {
      expect(ShxPayment.maxMemoBytes, 28);
    });
  });

  group('ShxPayment.buildPaymentOperation', () {
    test('pays SHx, to the given destination, for the given amount', () {
      final operation = ShxPayment.buildPaymentOperation(
        destinationAccountId: validDestination,
        amount: '12.5',
      ).build();

      final asset = operation.asset;
      expect(asset, isA<AssetTypeCreditAlphaNum4>());
      final creditAsset = asset as AssetTypeCreditAlphaNum4;
      expect(creditAsset.code, StrongholdConstants.shxAssetCode);
      expect(creditAsset.issuerId, StrongholdConstants.shxIssuerAccountId);
      expect(operation.destination.ed25519AccountId, validDestination);
      expect(operation.amount, '12.5');
    });
  });

  group('ShxPayment.send source status', () {
    for (final status in ShxAccountStatus.values) {
      if (status == ShxAccountStatus.shxReady) {
        continue;
      }

      test('rejects a source that is ${status.name}', () async {
        final source = ShxAccount(keyPair: KeyPair.random(), status: status);

        await expectLater(
          _send(source: source, destination: validDestination),
          _rejectedBeforeSending(ShxPaymentErrorCode.sourceNotReady),
        );
      });
    }

    test('checks the source status before the other inputs', () async {
      final source = ShxAccount(
        keyPair: KeyPair.random(),
        status: ShxAccountStatus.funded,
      );

      await expectLater(
        _send(source: source, destination: 'not-an-address', amount: 'abc'),
        _rejectedBeforeSending(ShxPaymentErrorCode.sourceNotReady),
      );
    });
  });

  group('ShxPayment.send destination', () {
    final invalidDestinations = <String, String>{
      'an empty string': '',
      'text that is not an address': 'not-an-address',
      'an address one character short': validDestination.substring(0, 55),
      'an address one character long': '${validDestination}A',
      'a lowercase address': validDestination.toLowerCase(),
      'an address with a leading space': ' $validDestination',
      'a muxed-looking address starting with M':
          'M${validDestination.substring(1)}',
      'a contract address':
          'CCKCKCPHYVXQD4NECBFJTFSCU2AMSJGCNG4O6K4JVRE2BLPR7WNDBQIQ',
      'an address with a corrupted checksum': _withCorruptedChecksum(
        validDestination,
      ),
    };

    for (final entry in invalidDestinations.entries) {
      test('rejects ${entry.key}', () async {
        await expectLater(
          _send(source: _readyAccount(), destination: entry.value),
          _rejectedBeforeSending(ShxPaymentErrorCode.invalidDestination),
        );
      });
    }

    test('rejects paying the source account itself', () async {
      final source = _readyAccount();

      await expectLater(
        _send(source: source, destination: source.accountId),
        _rejectedBeforeSending(ShxPaymentErrorCode.sameAccount),
      );
    });
  });

  group('ShxPayment.send amount', () {
    const invalidAmounts = <String>[
      '',
      ' ',
      'abc',
      'NaN',
      'Infinity',
      '-Infinity',
      '-1',
      '+1',
      '0',
      '0.0',
      '0.0000000',
      '.5',
      '1.',
      '1e3',
      '1,5',
      '1 ',
      ' 1',
      // Eight decimals: one more than Stellar allows.
      '1.12345678',
      // One stroop above the largest amount Stellar can represent.
      '922337203685.4775808',
      '922337203686',
      '9223372036854775808',
      // Arabic-Indic digits: digits, but not the ASCII ones this SDK accepts.
      '\u0661\u0660',
    ];

    for (final amount in invalidAmounts) {
      test('rejects "$amount"', () async {
        await expectLater(
          _send(
            source: _readyAccount(),
            destination: validDestination,
            amount: amount,
          ),
          _rejectedBeforeSending(ShxPaymentErrorCode.invalidAmount),
        );
      });
    }
  });

  group('ShxPayment.send memo', () {
    final invalidMemos = <String, String>{
      'an empty memo': '',
      'a memo of 29 ASCII bytes': 'a' * 29,
      // Eight characters, but 32 bytes of UTF-8: bytes are counted, not
      // characters.
      'a memo of 8 emoji (32 bytes)': '\u{1F680}' * 8,
      'a memo of 15 two-byte characters (30 bytes)': '\u00F1' * 15,
    };

    for (final entry in invalidMemos.entries) {
      test('rejects ${entry.key}', () async {
        await expectLater(
          _send(
            source: _readyAccount(),
            destination: validDestination,
            memo: entry.value,
          ),
          _rejectedBeforeSending(ShxPaymentErrorCode.invalidMemo),
        );
      });
    }
  });
}
