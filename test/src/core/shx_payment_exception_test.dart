import 'package:flutter_test/flutter_test.dart';
import 'package:stronghold_flutter_sdk/src/core/stronghold_exception.dart';

const _hash = 'a1b2c3';

// Result codes as documented by Stellar for the Payment operation and for
// transactions:
// https://developers.stellar.org/docs/data/apis/horizon/api-reference/errors/result-codes/operation-specific/payment
// https://developers.stellar.org/docs/data/apis/horizon/api-reference/errors/result-codes/transactions
const _cases =
    <
      ({
        String name,
        String? transactionCode,
        List<String> operationCodes,
        ShxPaymentErrorCode expected,
      })
    >[
      (
        name: 'a fee that would break the reserve',
        transactionCode: 'tx_insufficient_balance',
        operationCodes: [],
        expected: ShxPaymentErrorCode.insufficientXlmForFee,
      ),
      (
        name: 'a destination that does not exist',
        transactionCode: 'tx_failed',
        operationCodes: ['op_no_destination'],
        expected: ShxPaymentErrorCode.destinationNotFound,
      ),
      (
        name: 'a destination without a trustline',
        transactionCode: 'tx_failed',
        operationCodes: ['op_no_trust'],
        expected: ShxPaymentErrorCode.destinationNoTrustline,
      ),
      (
        name: 'a source without enough SHx',
        transactionCode: 'tx_failed',
        operationCodes: ['op_underfunded'],
        expected: ShxPaymentErrorCode.insufficientShx,
      ),
      (
        name: 'a destination at its trustline limit',
        transactionCode: 'tx_failed',
        operationCodes: ['op_line_full'],
        expected: ShxPaymentErrorCode.destinationLimitReached,
      ),
      (
        name: 'a malformed payment',
        transactionCode: 'tx_failed',
        operationCodes: ['op_malformed'],
        expected: ShxPaymentErrorCode.rejected,
      ),
      (
        name: 'a missing issuer',
        transactionCode: 'tx_failed',
        operationCodes: ['op_no_issuer'],
        expected: ShxPaymentErrorCode.rejected,
      ),
      (
        name: 'a source without a trustline',
        transactionCode: 'tx_failed',
        operationCodes: ['op_src_no_trust'],
        expected: ShxPaymentErrorCode.rejected,
      ),
      (
        name: 'a destination that is not authorized',
        transactionCode: 'tx_failed',
        operationCodes: ['op_not_authorized'],
        expected: ShxPaymentErrorCode.rejected,
      ),
      (
        name: 'a source that is not authorized',
        transactionCode: 'tx_failed',
        operationCodes: ['op_src_not_authorized'],
        expected: ShxPaymentErrorCode.rejected,
      ),
      (
        name: 'a bad sequence number',
        transactionCode: 'tx_bad_seq',
        operationCodes: [],
        expected: ShxPaymentErrorCode.rejected,
      ),
      (
        name: 'a bad signature',
        transactionCode: 'tx_bad_auth',
        operationCodes: [],
        expected: ShxPaymentErrorCode.rejected,
      ),
      (
        name: 'an insufficient fee',
        transactionCode: 'tx_insufficient_fee',
        operationCodes: [],
        expected: ShxPaymentErrorCode.rejected,
      ),
      (
        name: 'no result codes at all',
        transactionCode: null,
        operationCodes: [],
        expected: ShxPaymentErrorCode.rejected,
      ),
    ];

void main() {
  group('ShxPaymentException', () {
    test('is a StrongholdException', () {
      const error = ShxPaymentException(ShxPaymentErrorCode.rejected, 'boom');

      expect(error, isA<StrongholdException>());
    });

    test('keeps the code and message, and leaves the other fields null', () {
      const error = ShxPaymentException(
        ShxPaymentErrorCode.sameAccount,
        'same',
      );

      expect(error.code, ShxPaymentErrorCode.sameAccount);
      expect(error.message, 'same');
      expect(error.transactionHash, isNull);
      expect(error.transactionResultCode, isNull);
      expect(error.operationResultCodes, isNull);
    });

    test('names the code in toString', () {
      const error = ShxPaymentException(
        ShxPaymentErrorCode.insufficientShx,
        'low',
      );

      expect(error.toString(), 'ShxPaymentException(insufficientShx): low');
    });
  });

  group('ShxPaymentException.fromResultCodes', () {
    for (final testCase in _cases) {
      test('classifies ${testCase.name} as ${testCase.expected.name}', () {
        final error = ShxPaymentException.fromResultCodes(
          transactionHash: _hash,
          transactionResultCode: testCase.transactionCode,
          operationResultCodes: testCase.operationCodes,
        );

        expect(error.code, testCase.expected);
        expect(error.transactionHash, _hash);
        expect(error.transactionResultCode, testCase.transactionCode);
        expect(
          error.operationResultCodes,
          orderedEquals(testCase.operationCodes),
        );
      });
    }

    test('defaults the operation codes to an empty list', () {
      final error = ShxPaymentException.fromResultCodes(
        transactionHash: _hash,
        transactionResultCode: 'tx_bad_seq',
      );

      expect(error.operationResultCodes, isEmpty);
    });
  });
}
