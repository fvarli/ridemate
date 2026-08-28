import 'package:uuid/uuid.dart';

/// Mints the identifiers this client is responsible for.
///
/// WHY THE CLIENT MINTS A ROUTE ID AT ALL
///
/// It is the idempotency mechanism. A publication carries an id the client
/// chose before it sent anything, so a request repeated over a dropped
/// connection arrives with the same id and cannot become a second journey.
/// There is no Idempotency-Key header and no replay table on the server; the
/// primary key already answers the question one would ask.
///
/// WHY VERSION 7
///
/// The server validates the version, not merely the shape. A v7 is
/// time-ordered, so ids append to an index rather than scattering across it —
/// and a v4 is rejected at the boundary, which is a contract the client has to
/// keep rather than a preference it may hold.
///
/// An interface, because a test that cannot predict the id cannot assert that
/// a retry reused it.
abstract interface class RmUuidGenerator {
  /// A fresh UUIDv7.
  String v7();
}

class UuidV7Generator implements RmUuidGenerator {
  const UuidV7Generator();

  // Not hand-rolled. Getting the layout, the version nibble and the variant
  // bits right is a solved problem, and getting one of them subtly wrong would
  // fail at a server boundary long after the mistake was made.
  static const Uuid _uuid = Uuid();

  @override
  String v7() => _uuid.v7();
}
