// ─────────────────────────────────────────────────────────────
// RideMate — API responses
// ─────────────────────────────────────────────────────────────

/// A successful response, decoded no further than JSON.
///
/// Endpoint-specific shapes are the caller's business. This layer knows the
/// transport and the error contract and deliberately nothing about accounts,
/// tokens or passcodes — so adding an endpoint never means editing the client.
final class RmResponse {
  const RmResponse({required this.status, this.json});

  final int status;

  /// The decoded body, or `null` when there was none — a 204, or an empty
  /// body on any status.
  ///
  /// Typed as an object rather than `Object?` because every documented Phase 9
  /// success body is a JSON object or absent. A success carrying an array or a
  /// scalar is not something the contract describes, so the client refuses it
  /// rather than handing the caller something it will have to guess about.
  final Map<String, Object?>? json;
}
