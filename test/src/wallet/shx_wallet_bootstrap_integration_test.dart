@Tags(['integration'])
library;

// Integration tests: these hit Stellar Testnet for real via Friendbot
// and Horizon. Kept separate from the pure unit tests in
// shx_wallet_bootstrap_test.dart, per this project's convention.

import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';
import 'package:stronghold_flutter_sdk/src/core/stronghold_exception.dart';
import 'package:stronghold_flutter_sdk/src/wallet/shx_wallet.dart';

void main() {
  group('ShxWallet.bootstrapForShx on Testnet', () {
    test(
      'rolls back the account creation when the SHx trustline fails',
      () async {
        // A funded Testnet account to act as the funding source.
        final funder = await ShxWallet.fundOnTestnet(
          ShxWallet.createPending(),
        );
        final target = ShxWallet.createPending();

        // The SHx issuer does not exist on Testnet, so the second
        // operation (the trustline) must fail with op_no_issuer. Seeing
        // that code, and not tx_bad_auth, also shows that both
        // signatures were accepted: authorization is checked before any
        // operation runs.
        await expectLater(
          ShxWallet.bootstrapForShx(
            account: target,
            sdk: StellarSDK.TESTNET,
            network: Network.TESTNET,
            fundingSourceKeyPair: funder.keyPair,
            startingBalance: '2',
          ),
          throwsA(
            isA<StrongholdException>().having(
              (e) => e.message,
              'message',
              contains('op_no_issuer'),
            ),
          ),
        );

        // Atomicity: the first operation (the account creation) must
        // have been rolled back too, so the target never reached the
        // ledger and Horizon answers 404.
        await expectLater(
          StellarSDK.TESTNET.accounts.account(target.accountId),
          throwsA(
            isA<ErrorResponse>().having((e) => e.code, 'code', 404),
          ),
        );
      },
    );

    test(
      'creates a funded, SHx-ready account (happy path)',
      () {},
      skip:
          'Needs a funded Mainnet account: the real SHx issuer only exists '
          'on Mainnet. See docs-sdk/phase-2/shx-trustline/.',
    );
  });
}
