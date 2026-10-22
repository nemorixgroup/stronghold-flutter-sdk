// Demonstrates the account onboarding flow available as of 0.0.3-dev:
// generating an identity and funding it on Testnet.
//
// Note: this file is illustrative. stellar_flutter_sdk depends on Flutter, so
// it cannot run with `dart run`. Copy the function into a Flutter app and
// call it from there.
//

import 'package:stronghold_flutter_sdk/stronghold_flutter_sdk.dart';

Future<void> accountOnboardingExample() async {
  print('Generating a new SHx account...');
  final pending = ShxWallet.createPending();
  print('Address: ${pending.accountId}');
  print('Status: ${pending.status}');

  print('\nFunding on Testnet via Friendbot...');
  final funded = await ShxWallet.fundOnTestnet(pending);
  print('Status: ${funded.status}');

  print('\nDone. This account now holds XLM on Testnet, but cannot');
  print('yet hold SHx, that requires a trustline (coming in 0.0.4-dev).');
}
