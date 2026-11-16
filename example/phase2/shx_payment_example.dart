// Demonstrates sending SHx from one account to another, with an optional
// memo, and handling each way the payment can fail.
//
// IMPORTANT: like the trustline and bootstrap examples, this one requires
// Mainnet. The real SHx issuer only exists on Mainnet, so no Testnet account
// can hold SHx. It moves real SHx: use a small amount the first time.
//
// You need:
// - a Mainnet account that already holds SHx and its trustline (see
//   shx_trustline_example.dart), and
// - a destination account that exists on Mainnet and also holds the SHx
//   trustline.
//
// Note: this file is illustrative. stellar_flutter_sdk depends on Flutter, so
// it cannot run with `dart run`. Copy the function into a Flutter app and
// call it from there.

import 'package:stronghold_flutter_sdk/stronghold_flutter_sdk.dart';

Future<void> shxPaymentExample() async {
  // Replace with the secret seed of the paying Mainnet account. An app would
  // load it from secure storage, never hard-code it.
  final source = ShxAccount(
    keyPair: KeyPair.fromSecretSeed('S...'),
    status: ShxAccountStatus.shxReady,
  );

  // Replace with the recipient's Stellar address (it must start with G).
  const destination = 'G...';

  try {
    final txHash = await ShxPayment.send(
      source: source,
      destinationAccountId: destination,
      amount: '10.5',
      sdk: StellarSDK.PUBLIC,
      network: Network.PUBLIC,
      // Optional, up to 28 bytes of UTF-8. Exchanges that list SHx often
      // need a memo to credit a deposit.
      memo: 'invoice 1042',
    );
    print('Paid. Transaction: $txHash');
  } on ShxPaymentException catch (error) {
    if (error.code == ShxPaymentErrorCode.outcomeUnknown) {
      // The network did not give a definitive answer: the payment may have
      // been applied. Do NOT send again blindly, or you can pay twice. Look
      // up the transaction by its hash first.
      print('Unknown outcome. Check transaction ${error.transactionHash}');
    } else if (error.code == ShxPaymentErrorCode.destinationNoTrustline) {
      print('The recipient must add the SHx trustline before receiving SHx.');
    } else if (error.code == ShxPaymentErrorCode.destinationNotFound) {
      print('The recipient account does not exist on this network yet.');
    } else if (error.code == ShxPaymentErrorCode.insufficientShx) {
      print('Not enough SHx to send this amount.');
    } else if (error.code == ShxPaymentErrorCode.insufficientXlmForFee) {
      print('Not enough XLM to pay the fee: top up the paying account.');
    } else {
      // Any exception that is not outcomeUnknown means nothing was applied.
      print('Payment failed (${error.code.name}): ${error.message}');
    }
  }
}
