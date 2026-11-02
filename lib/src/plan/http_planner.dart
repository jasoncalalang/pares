import 'dart:convert';

import 'package:http/http.dart' as http;

import 'plan_json.dart';
import 'plan_models.dart';
import 'planner.dart';

/// A [Planner] that talks to the MealPal server (see server/README.md).
///
/// Every call is one request. The server keeps no state between them, so
/// callers poll [fetch] to move a plan along.
class HttpPlanner implements Planner {
  HttpPlanner(
    this.baseUrl, {
    this.appKey,
    http.Client? client,
    this.requestTimeout = const Duration(seconds: 20),
  }) : _client = client ?? http.Client();

  /// The server's root. May end in a slash or carry a path prefix.
  final Uri baseUrl;

  /// Sent as `X-MealPal-Key` when not empty.
  final String? appKey;

  final Duration requestTimeout;
  final http.Client _client;

  @override
  Future<PlanSnapshot> start(PlanBrief brief) =>
      _send('POST', const ['plans'], body: brief.toJson());

  @override
  Future<PlanSnapshot> fetch(String id) => _send('GET', ['plans', id]);

  @override
  Future<PlanSnapshot> swap(
    String id,
    Weekday day,
    MealSlot slot, {
    String? note,
  }) => _send(
    'POST',
    ['plans', id, 'swaps'],
    body: {
      'weekday': day.name,
      'slot': slot.name,
      'note': ?note,
    },
  );

  void close() => _client.close();

  Uri _url(List<String> parts) => baseUrl.replace(
    pathSegments: [
      ...baseUrl.pathSegments.where((s) => s.isNotEmpty),
      ...parts,
    ],
    query: null,
    fragment: null,
  );

  Future<PlanSnapshot> _send(
    String method,
    List<String> parts, {
    Map<String, Object?>? body,
  }) async {
    final request = http.Request(method, _url(parts));
    final key = appKey;
    if (key != null && key.isNotEmpty) request.headers['X-MealPal-Key'] = key;
    request.headers['Accept'] = 'application/json';
    if (body != null) {
      request.headers['Content-Type'] = 'application/json; charset=utf-8';
      request.body = jsonEncode(body);
    }

    final http.Response response;
    try {
      response = await http.Response.fromStream(
        await _client.send(request).timeout(requestTimeout),
      ).timeout(requestTimeout);
    } catch (_) {
      throw const PlannerException(
        PlannerErrorKind.network,
        message: 'The server did not answer.',
      );
    }

    Object? decoded;
    try {
      decoded = jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException {
      decoded = null;
    }

    final status = response.statusCode;
    if (status >= 200 && status < 300) return planSnapshotFromJson(decoded);

    final message = errorMessageFromJson(decoded);
    final kind = switch (status) {
      400 => PlannerErrorKind.rejected,
      401 => PlannerErrorKind.unauthorized,
      404 => PlannerErrorKind.notFound,
      409 => PlannerErrorKind.busy,
      >= 500 => PlannerErrorKind.unavailable,
      _ => PlannerErrorKind.badResponse,
    };
    throw PlannerException(
      kind,
      message: message,
      problems: kind == PlannerErrorKind.rejected
          ? errorProblemsFromJson(decoded)
          : const [],
    );
  }
}
