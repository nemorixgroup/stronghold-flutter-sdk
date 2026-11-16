import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';
import 'package:stronghold_flutter_sdk/src/asset/shx_asset.dart';

// ShxPayment.send checks the memo size in UTF-8 bytes and then hands the text
// to the SDK's Memo.text. These tests check, with no network, that the SDK
// agrees with that check: it accepts the same memos, rejects the same memos,
// and puts exactly the UTF-8 bytes of the text into the signed transaction.
//
// They exercise the SDK calls that send uses, not send itself.

// A signed, serialized payment carrying [memo], built the way send builds it.
List<int> _signedEnvelopeBytes(String memo) {
  final source = KeyPair.random();
  final destination = KeyPair.random();
  final transaction =
      TransactionBuilder(Account.fromAccountId(source.accountId, BigInt.zero))
          .addOperation(
            ShxPayment.buildPaymentOperation(
              destinationAccountId: destination.accountId,
              amount: '1',
            ).build(),
          )
          .addMemo(Memo.text(memo))
          .build()
        ..sign(source, Network.TESTNET);
  return base64Decode(transaction.toEnvelopeXdrBase64());
}

// How a text memo looks in the Stellar XDR: the type (MEMO_TEXT = 1), the
// length, the bytes, and zero padding up to a multiple of 4 bytes. A long,
// specific pattern, so a short memo cannot match by coincidence.
List<int> _memoTextXdr(String text) {
  final data = utf8.encode(text);
  final padding = (4 - data.length % 4) % 4;
  return [
    0,
    0,
    0,
    1,
    0,
    0,
    0,
    data.length,
    ...data,
    ...List<int>.filled(padding, 0),
  ];
}

bool _containsSequence(List<int> haystack, List<int> needle) {
  for (var start = 0; start + needle.length <= haystack.length; start++) {
    var matches = true;
    for (var offset = 0; offset < needle.length; offset++) {
      if (haystack[start + offset] != needle[offset]) {
        matches = false;
        break;
      }
    }
    if (matches) {
      return true;
    }
  }
  return false;
}

void main() {
  group('Memo.text accepts what ShxPayment.send accepts', () {
    final acceptedMemos = <String, String>{
      'a 1-byte memo': '1',
      'a memo of 28 ASCII bytes': 'a' * 28,
      'a memo of 14 two-byte characters (28 bytes)': '\u00F1' * 14,
      'a memo of 7 emoji (28 bytes)': '\u{1F680}' * 7,
    };

    for (final entry in acceptedMemos.entries) {
      test('puts ${entry.key} into the transaction as exact UTF-8', () {
        final envelope = _signedEnvelopeBytes(entry.value);

        expect(
          _containsSequence(envelope, _memoTextXdr(entry.value)),
          isTrue,
          reason: 'the memo bytes were not found in the signed transaction',
        );
      });
    }
  });

  group('Memo.text rejects what ShxPayment.send rejects', () {
    final rejectedMemos = <String, String>{
      'a memo of 29 ASCII bytes': 'a' * 29,
      // Eight characters, but 32 bytes of UTF-8.
      'a memo of 8 emoji (32 bytes)': '\u{1F680}' * 8,
      'a memo of 15 two-byte characters (30 bytes)': '\u00F1' * 15,
    };

    for (final entry in rejectedMemos.entries) {
      test('rejects ${entry.key}', () {
        expect(
          () => Memo.text(entry.value),
          throwsA(isA<MemoTooLongException>()),
        );
      });
    }
  });
}
