/// SHx governance voting, built on classic Stellar ManageData operations.
///
/// Confirmed mechanism (docs.shx.stronghold.co/shx/shx-governance-rules):
/// no Soroban contract involved for voting. A ManageData entry is
/// written to the voting account with:
///   name  => `"SHX::PROP:<proposal number>"`
///   value => comma-delimited vote positions, e.g. "FOR,40"
/// The account's LAST ManageData write within the voting window is the
/// vote that counts.
library;

import 'dart:convert';

import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

// ---- Vote Model ----

/// A single governance vote for a SHx proposal.
class ShxVote {
  /// Creates a [ShxVote] for [proposalNumber] with [votePositions].
  const ShxVote({required this.proposalNumber, required this.votePositions});

  /// The SHx proposal number being voted on.
  final int proposalNumber;

  /// Comma-delimited vote positions, e.g. "FOR" or "FOR,40" for
  /// multi-question proposals.
  final String votePositions;

  /// The ManageData entry name this vote is written under.
  String get dataEntryName => 'SHX::PROP:$proposalNumber';
}

// ---- Vote Operation Builder ----

/// Builds the Stellar operations that cast or clear a SHx governance
/// vote.
class ShxGovernance {
  ShxGovernance._();

  /// Builds the ManageData operation that casts [vote].
  ///
  /// Per the reference implementation (vote.stronghold.co), pair this
  /// with [buildClearVoteOperation] in the same transaction to avoid an
  /// ongoing base reserve cost; clearing is optional and does not
  /// affect counting.
  static ManageDataOperationBuilder buildCastVoteOperation(ShxVote vote) {
    return ManageDataOperationBuilder(
      vote.dataEntryName,
      utf8.encode(vote.votePositions),
    );
  }

  /// Builds the follow-up operation clearing the ManageData entry.
  static ManageDataOperationBuilder buildClearVoteOperation(ShxVote vote) {
    return ManageDataOperationBuilder(vote.dataEntryName, null);
  }

  // TODO(nemorixgroup): add a read helper that fetches an account's
  // current vote for a given proposal via Horizon's account data
  // endpoint, decoding the base64-encoded ManageData value back into
  // vote positions.
}
