// Demonstrates reading XLM and SHx balances for an account.
//
// Note: this file is illustrative. stellar_flutter_sdk depends on Flutter, so
// it cannot run with `dart run`. Copy the function into a Flutter app and
// call it from there.

import 'package:stronghold_flutter_sdk/stronghold_flutter_sdk.dart';

Future<void> shxBalanceExample() async {
  print('Generating and funding a Testnet account...');
  final account = await ShxWallet.fundOnTestnet(ShxWallet.createPending());

  final xlm = await ShxBalance.getXlmBalance(
    accountId: account.accountId,
    sdk: StellarSDK.TESTNET,
  );
  print('XLM balance: $xlm');

  final shx = await ShxBalance.getShxBalance(
    accountId: account.accountId,
    sdk: StellarSDK.TESTNET,
  );
  print('SHx balance: $shx');
  print('(0 is expected here, this account has no SHx trustline yet)');
}
