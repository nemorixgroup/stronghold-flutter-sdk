// Demonstrates bootstrapForShx, the one-call path from a freshly generated
// account to an SHx-ready one: create, fund, and open the SHx trustline in a
// single atomic transaction.
//
// IMPORTANT: like the trustline example, this one requires Mainnet. The real
// SHx issuer only exists on Mainnet; running this against Testnet fails with
// `op_no_issuer` and, because the transaction is atomic, creates nothing (see
// docs-sdk/phase-2/shx-trustline/ and docs-sdk/phase-2/bootstrap-for-shx/).
// You need a Mainnet account holding a few XLM to act as the funding source.
//
// bootstrapForShx needs both secrets (the funding source and the new
// account) in the same place. If they live on different devices, use
// ShxWallet.createAndFund and ShxWallet.establishShxTrustline as separate
// steps instead.
//
// Note: this file is illustrative. stellar_flutter_sdk depends on Flutter, so
// it cannot run with `dart run`. Copy the function into a Flutter app and
// call it from there.

import 'package:stronghold_flutter_sdk/stronghold_flutter_sdk.dart';

Future<void> shxBootstrapExample() async {
  // Replace with the secret seed of a real Mainnet account that holds XLM.
  // It pays the new account's starting balance and the transaction fee.
  final fundingSource = KeyPair.fromSecretSeed('S...');

  // The new account to onboard. Persist its secret seed somewhere safe
  // BEFORE submitting: once the account holds funds, losing the key means
  // losing them.
  final pending = ShxWallet.createPending();
  print('New account: ${pending.accountId}');

  // The minimum is ShxWallet.minimumBootstrapBalance: two base reserves plus
  // one for the trustline. Add headroom on top, since an account holding
  // exactly the minimum has no spendable balance left.
  const startingBalance = '2';
  print(
    'Minimum: ${ShxWallet.minimumBootstrapBalance} XLM, '
    'sending: $startingBalance XLM',
  );

  final ready = await ShxWallet.bootstrapForShx(
    account: pending,
    sdk: StellarSDK.PUBLIC,
    network: Network.PUBLIC,
    fundingSourceKeyPair: fundingSource,
    startingBalance: startingBalance,
  );
  print('Status: ${ready.status}'); // ShxAccountStatus.shxReady

  final xlm = await ShxBalance.getXlmBalance(
    accountId: ready.accountId,
    sdk: StellarSDK.PUBLIC,
  );
  final shx = await ShxBalance.getShxBalance(
    accountId: ready.accountId,
    sdk: StellarSDK.PUBLIC,
  );
  print('XLM balance: $xlm');
  print('SHx balance: $shx'); // '0': the account can now receive SHx
}
