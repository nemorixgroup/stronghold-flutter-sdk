// Demonstrates establishing a SHx trustline, the step that moves an
// account from "funded" to "shxReady".
//
// IMPORTANT: unlike the other Phase 2 examples, this one requires
// Mainnet. The real SHx issuer only exists on Mainnet; running this
// against Testnet fails with `op_no_issuer` (see
// docs-sdk/phase-2/testnet-mainnet-asset-boundary/ for why). You will
// need a Mainnet account with a small amount of real XLM (the
// trustline reserve, a few cents' worth, recoverable by removing the
// trustline later via ShxTrustline.buildRemoveOperation()).
//
// Run with: dart run example/phase2/shx_trustline_example.dart

import 'package:stronghold_flutter_sdk/stronghold_flutter_sdk.dart';

Future<void> main() async {
  // Replace with a real, funded Mainnet account's secret seed.
  final myKeyPair = KeyPair.fromSecretSeed('S...');
  final account = ShxAccount(
    keyPair: myKeyPair,
    status: ShxAccountStatus.funded,
  );

  print('Opening a SHx trustline for ${account.accountId}...');
  final ready = await ShxWallet.establishShxTrustline(
    account: account,
    sdk: StellarSDK.PUBLIC,
    network: Network.PUBLIC,
  );

  print('Status: ${ready.status}'); // ShxAccountStatus.shxReady
  print('This account can now send and receive SHx.');
}
