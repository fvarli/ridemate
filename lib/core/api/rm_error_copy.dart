// ─────────────────────────────────────────────────────────────
// RideMate — failures, in the member's language
//
// The backend sends `code` and `message`. `code` is the contract; `message` is
// developer-facing English the client must never display. This is the mapping
// that makes that practical rather than merely stated — and RmFailure does not
// carry the message at all, so there is nothing to accidentally show.
//
// Takes AppLocalizations rather than BuildContext: the API layer must not
// depend on the widget tree, and a caller that already has the localizations
// can map a failure inside a controller or a test.
// ─────────────────────────────────────────────────────────────

import '../../l10n/app_localizations.dart';
import 'rm_error_code.dart';
import 'rm_failure.dart';

extension RmFailureCopy on RmFailure {
  /// What to put in front of the member.
  ///
  /// EXHAUSTIVE ON PURPOSE. There is no `_` branch, so adding a tenth server
  /// code makes this stop compiling and forces someone to decide what it says
  /// — rather than the new code quietly joining the "something went wrong"
  /// pile. Forward compatibility is already handled a layer down:
  /// RmErrorCode.fromWire turns a code this build has never heard of into
  /// [RmErrorCode.unexpected], which lands on the safe copy below.
  ///
  /// `request_id` is deliberately absent. It is diagnostics, and a UUID in a
  /// sentence tells a member nothing while making the app look broken.
  String copy(AppLocalizations l10n) {
    if (isTransport) {
      return l10n.errorNetwork;
    }

    return switch (code) {
      // The four a member can act on, or at least understand.
      RmErrorCode.validationFailed => l10n.errorValidation,
      RmErrorCode.unauthenticated => l10n.errorUnauthenticated,
      // Distinct from unauthenticated on purpose: signing in again is exactly
      // what a suspended member cannot do, so telling them to would be advice
      // that fails forever.
      RmErrorCode.forbidden => l10n.errorForbidden,
      RmErrorCode.rateLimited => l10n.errorRateLimited,
      // A conflict is a specific, explainable state — the request cannot be
      // applied to what the server currently holds. Folding it into
      // "something went wrong" told a member nothing they could act on.
      RmErrorCode.conflict => l10n.errorConflict,

      // The rest describe a client or server defect rather than anything the
      // member did. They get one honest sentence instead of five variations
      // of it, because the difference between them is not actionable.
      RmErrorCode.badRequest ||
      RmErrorCode.notFound ||
      RmErrorCode.methodNotAllowed ||
      RmErrorCode.internalError ||
      RmErrorCode.unexpected => l10n.errorUnexpected,
    };
  }
}
