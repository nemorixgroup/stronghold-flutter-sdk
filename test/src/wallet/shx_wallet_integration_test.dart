@Tags(['integration'])
library;

// Integration tests: these hit Stellar Testnet for real via Friendbot.
// Slower and dependent on Testnet being up; kept separate from the
// pure unit tests in shx_wallet_test.dart for that reason.

import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';
import 'package:stronghold_flutter_sdk/src/wallet/shx_account.dart';
import 'package:stronghold_flutter_sdk/src/wallet/shx_wallet.dart';

void main() {
  group('ShxWallet.fundOnTestnet', () {
    test('funds a pending account and updates its status', () async {
      final pending = ShxWallet.createPending();

      final funded = await ShxWallet.fundOnTestnet(pending);

      expect(funded.status, ShxAccountStatus.funded);
      expect(funded.accountId, pending.accountId);
    });

    test(
      'throws StrongholdException for an invalid account id',
      () async {
        final invalid = ShxAccount(
          keyPair: ShxWallet.generate(),
          status: ShxAccountStatus.pending,
        );

        // A syntactically invalid accountId is the simplest reliable way
        // to force Friendbot to decline without depending on Testnet
        // being in any particular state.
        // ignore: avoid_dynamic_calls
        final tampered = ShxAccount(
          keyPair: invalid.keyPair,
          status: ShxAccountStatus.pending,
        );

        expect(
          () => ShxWallet.fundOnTestnet(tampered),
          anything, // placeholder, see note below
        );
      },
      skip: 'Needs a reliable way to force a Friendbot failure; see note',
    );
  });

  group('ShxWallet.createAndFund', () {
    test(
      'creates and funds a new account using a Testnet funding source',
      () async {
        // Funding source: a Testnet account funded via Friendbot, reusing
        // fundOnTestnet so this test doesn't depend on any hardcoded
        // pre-funded account.
        final fundingSource = await ShxWallet.fundOnTestnet(
          ShxWallet.createPending(),
        );

        final target = ShxWallet.createPending();

        final result = await ShxWallet.createAndFund(
          account: target,
          sdk: StellarSDK.TESTNET,
          network: Network.TESTNET,
          fundingSourceKeyPair: fundingSource.keyPair,
          startingBalance: '5',
        );

        expect(result.status, ShxAccountStatus.funded);
        expect(result.accountId, target.accountId);
      },
    );
  });

  // TrustLine
  group('ShxWallet.establishShxTrustline', () {
    test(
      'opens a trustline and marks the account as shxReady',
      () async {
        final funded = await ShxWallet.fundOnTestnet(ShxWallet.createPending());

        final ready = await ShxWallet.establishShxTrustline(
          account: funded,
          sdk: StellarSDK.TESTNET,
          network: Network.TESTNET,
        );

        expect(ready.status, ShxAccountStatus.shxReady);
        expect(ready.accountId, funded.accountId);
      },
      skip:
          'The real SHx issuer only exists on Mainnet (op_no_issuer on '
          'Testnet). Requires a funded Mainnet test account; deferred until '
          'one is available. See ShxTrustline unit tests for construction - '
          'level coverage in the meantime.',
    );
  });
}
