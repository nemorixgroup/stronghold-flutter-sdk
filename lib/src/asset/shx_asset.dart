/// SHx asset operations on Stellar: trustlines and payments.
///
/// API confirmed against stellar_flutter_sdk v3.3.0 documentation
/// (Soneso/stellar_flutter_sdk, documentation/soroban.md and README quick
/// examples): Asset.createNonNativeAsset, ChangeTrustOperationBuilder,
/// PaymentOperationBuilder.
library;

import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';
import '../core/stronghold_network.dart';

// ---- The SHx Asset ----

class ShxAsset {
  ShxAsset._();

  /// The SHx asset descriptor, ready to use in any Stellar operation.
  static Asset get asset => Asset.createNonNativeAsset(
    StrongholdConstants.shxAssetCode,
    StrongholdConstants.shxIssuerAccountId,
  );
}

// ---- Trustlines ----
//
// A Stellar account cannot receive SHx until it establishes a trustline
// toward the SHx issuer. This is a mandatory first step, not an edge case.

class ShxTrustline {
  ShxTrustline._();

  /// Builds a ChangeTrust operation authorizing the source account to hold
  /// SHx, up to [limit] (defaults to the SDK's maximum representable amount).
  static ChangeTrustOperationBuilder buildEstablishOperation({String? limit}) {
    return ChangeTrustOperationBuilder(
      ShxAsset.asset,
      limit ?? ChangeTrustOperationBuilder.MAX_LIMIT,
    );
  }

  /// Builds a ChangeTrust operation removing the trustline (limit = "0").
  /// Only succeeds if the account's SHx balance is zero.
  static ChangeTrustOperationBuilder buildRemoveOperation() {
    return ChangeTrustOperationBuilder(ShxAsset.asset, '0');
  }
}

// ---- Payments ----

class ShxPayment {
  ShxPayment._();

  /// Builds a simple SHx payment operation. The destination account MUST
  /// already have a trustline toward the SHx issuer (see [ShxTrustline]).
  static PaymentOperationBuilder buildPaymentOperation({
    required String destinationAccountId,
    required String amount,
  }) {
    return PaymentOperationBuilder(
      destinationAccountId,
      ShxAsset.asset,
      amount,
    );
  }

  // TODO(Phase 1): add buildPathPaymentOperation wrapping
  // PathPaymentStrictSendOperationBuilder / PathPaymentStrictReceiveOperationBuilder
  // for cross-asset SHx conversions (relevant to the NemorixPay corridor use case).
}
