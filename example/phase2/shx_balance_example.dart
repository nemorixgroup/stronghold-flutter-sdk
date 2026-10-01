// Demonstrates reading XLM and SHx balances for an account.
//
// Run with: dart run example/phase2/shx_balance_example.dart

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
