// ─────────────────────────────────────────────────────────────
// RideMate — API client
//
// The only place in the application that speaks HTTP.
//
// `package:http` is imported here and nowhere else; a test enforces that.
// Feature code depends on this client, so replacing the transport — or the
// package — is a change confined to this directory rather than a search across
// the app.
//
// Deliberately not a framework. There are no interceptors, no retry policy, no
// offline queue and no request logging, because Phase 9 needs none of them and
// each would be infrastructure written before the requirement that shapes it.
// ─────────────────────────────────────────────────────────────

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/rm_api_config.dart';
import 'rm_error_code.dart';
import 'rm_failure.dart';
import 'rm_response.dart';

/// Sends requests to the RideMate backend and returns decoded responses.
///
/// Throws [RmFailure] for every failure, and nothing else: a caller never has
/// to catch a transport exception or a decoding error.
final class RmApiClient {
  /// The base URL is injected rather than read from configuration.
  ///
  /// Configuration resolves at compile time from a --dart-define, which a test
  /// cannot vary. Taking a [Uri] means the whole client is testable without
  /// every test needing a define, and it keeps validation in exactly one place
  /// — [RmApiConfig] — instead of being repeated here.
  RmApiClient({required http.Client transport, required Uri baseUrl})
    : _transport = transport,
      _baseUrl = baseUrl;

  /// The composition seam. The only place configuration and transport meet.
  factory RmApiClient.fromConfig({required http.Client transport}) =>
      RmApiClient(
        transport: transport,
        baseUrl: Uri.parse(RmApiConfig.baseUrl),
      );

  final http.Client _transport;
  final Uri _baseUrl;

  /// Applied last, so a caller cannot remove them by accident.
  ///
  /// Passing a headers map is how `Authorization` gets attached, and a caller
  /// building one from scratch would otherwise drop content negotiation
  /// without noticing — producing an HTML error page the decoder cannot read,
  /// on the day something goes wrong.
  static const Map<String, String> _accept = <String, String>{
    'Accept': 'application/json',
  };

  Future<RmResponse> get(
    String path, {
    Map<String, String>? query,
    Map<String, String>? headers,
  }) => _send(
    () => _transport.get(_uri(path, query), headers: _headers(headers)),
  );

  Future<RmResponse> post(
    String path, {
    Map<String, Object?>? json,
    Map<String, String>? query,
    Map<String, String>? headers,
  }) => _send(
    () => _transport.post(
      _uri(path, query),
      headers: _headers(headers, hasJsonBody: json != null),
      body: json == null ? null : jsonEncode(json),
    ),
  );

  void close() => _transport.close();

  /// Joins a request path onto the configured base, preserving both.
  ///
  /// Segment-wise rather than by string concatenation, which gets two things
  /// wrong that are easy to miss: `base + '/api'` doubles the separator when
  /// the base ends in one, and `Uri.resolve('/api/v1/me')` REPLACES the base
  /// path — so a backend deployed under `https://host/ridemate` would silently
  /// be called at `https://host/api/v1/me`. Empty segments are dropped, so a
  /// leading slash on the request path cannot escape the prefix.
  Uri _uri(String path, Map<String, String>? query) {
    final List<String> segments = <String>[
      ..._baseUrl.pathSegments.where((String s) => s.isNotEmpty),
      ...path.split('/').where((String s) => s.isNotEmpty),
    ];

    return _baseUrl.replace(
      pathSegments: segments,
      // Passing an empty map would append a bare '?', so absent stays absent.
      queryParameters: query == null || query.isEmpty ? null : query,
    );
  }

  Map<String, String> _headers(
    Map<String, String>? caller, {
    bool hasJsonBody = false,
  }) => <String, String>{
    ...?caller,
    ..._accept,
    if (hasJsonBody) 'Content-Type': 'application/json',
  };

  /// Runs a request and converts everything it can throw into [RmFailure].
  Future<RmResponse> _send(Future<http.Response> Function() request) async {
    final http.Response response;

    try {
      response = await request();
    } on Object {
      // Every transport error, deliberately caught as one: ClientException,
      // SocketException, HandshakeException, TimeoutException. Naming them
      // individually would let an unnamed one escape as itself, and the
      // caller's response to all of them is identical.
      throw const RmFailure.transport();
    }

    return _interpret(response);
  }

  RmResponse _interpret(http.Response response) {
    final int status = response.statusCode;
    final Map<String, Object?>? body = _decode(response);

    if (status >= 200 && status < 300) {
      // A success that carried a body which is not a JSON object is not
      // something the contract describes. Refusing beats handing the caller
      // something it has to guess about.
      if (response.bodyBytes.isNotEmpty && body == null) {
        throw RmFailure.fromBackend(
          status: status,
          code: RmErrorCode.unexpected,
          requestId: _requestIdHeader(response),
        );
      }

      return RmResponse(status: status, json: body);
    }

    // The documented envelope: {"error": {code, message, details?, request_id}}.
    // `message` is read past deliberately — see RmFailure.
    final Object? error = body?['error'];
    final Map<String, Object?>? fields = error is Map<String, Object?>
        ? error
        : null;

    return throw RmFailure.fromBackend(
      status: status,
      // Total by construction: a missing, malformed or unknown code all become
      // `unexpected` rather than throwing while handling a failure.
      code: RmErrorCode.fromWire(fields?['code']),
      requestId: _requestId(fields) ?? _requestIdHeader(response),
    );
  }

  /// Decodes a JSON object body, or `null` if there is not one.
  ///
  /// UTF-8 explicitly, from the raw bytes. `http.Response.body` picks its
  /// encoding from the Content-Type charset and falls back to LATIN-1 when
  /// none is given — which is exactly what Laravel sends. Reading `.body`
  /// would quietly mangle every Turkish character the backend ever returns.
  Map<String, Object?>? _decode(http.Response response) {
    if (response.bodyBytes.isEmpty) {
      return null;
    }

    try {
      final Object? decoded = jsonDecode(utf8.decode(response.bodyBytes));

      return decoded is Map<String, Object?> ? decoded : null;
    } on FormatException {
      return null;
    }
  }

  static String? _requestId(Map<String, Object?>? fields) {
    final Object? value = fields?['request_id'];

    return value is String ? value : null;
  }

  /// The correlation id also travels as a header, which is the only place it
  /// survives when the body is unreadable — precisely when it is most needed.
  static String? _requestIdHeader(http.Response response) =>
      response.headers['x-request-id'];
}
