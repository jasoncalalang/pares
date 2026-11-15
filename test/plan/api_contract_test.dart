import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mealpal_ph/mealpal_ph.dart';
import 'package:test/test.dart';

/// server/openapi.json is the API's contract. The server's
/// OpenApiContractTest holds the server to it; this holds [HttpPlanner] to it,
/// so the two sides cannot drift apart without a red test.
final Map<String, Object?> _contract = jsonDecode(
  File('server/openapi.json').readAsStringSync(),
) as Map<String, Object?>;

Map<String, Object?> _map(Object? o) => o! as Map<String, Object?>;

Map<String, Object?> get _paths => _map(_contract['paths']);

Map<String, Object?> _schema(String name) =>
    _map(_map(_map(_contract['components'])['schemas'])[name]);

Set<String> _required(String schema) => {
  ...(_schema(schema)['required']! as List).cast<String>(),
};

Set<String> _properties(String schema) =>
    _map(_schema(schema)['properties']).keys.toSet();

Set<String> _enum(String schema) => {
  ...(_schema(schema)['enum']! as List).cast<String>(),
};

/// The contract's path and operation that serve [r], reading a `{param}`
/// segment as any value. Null when the contract has no such call.
(String, Map<String, Object?>)? _operation(http.BaseRequest r) {
  final segments = r.url.pathSegments;
  for (final MapEntry(key: path, value: ops) in _paths.entries) {
    final template = path.split('/').where((s) => s.isNotEmpty).toList();
    if (template.length != segments.length) continue;
    var matches = true;
    for (var i = 0; i < template.length && matches; i++) {
      final t = template[i];
      matches = (t.startsWith('{') && t.endsWith('}')) || t == segments[i];
    }
    if (!matches) continue;
    final op = _map(ops)[r.method.toLowerCase()];
    return op == null ? null : (path, _map(op));
  }
  return null;
}

final _brief = PlanBrief(
  targetKcal: 2087,
  budgetPhp: 2000,
  goal: Goal.lose,
  storeIds: ['palengke', 'puregold'],
);

const _building = {
  'id': 'p1',
  'status': 'building',
  'week': null,
  'message': null,
};

/// Every call the app makes, by name.
final _calls = <String, Future<Object?> Function(HttpPlanner)>{
  'start': (p) => p.start(_brief),
  'fetch': (p) => p.fetch('p1'),
  'swap': (p) =>
      p.swap('p1', Weekday.tue, MealSlot.lunch, note: 'something cheaper'),
  'swap without a note': (p) => p.swap('p1', Weekday.tue, MealSlot.lunch),
};

/// A planner whose server answers every call with [status] and [body];
/// [seen] collects what it was sent.
HttpPlanner _answering(int status, Object body, [List<http.Request>? seen]) =>
    HttpPlanner(
      Uri.parse('https://mealpal.example'),
      appKey: 'key',
      client: MockClient((r) async {
        seen?.add(r);
        return http.Response(
          jsonEncode(body),
          status,
          headers: {'content-type': 'application/json'},
        );
      }),
    );

/// Makes [call] against a server that accepts it, and returns the request.
Future<http.Request> _send(Future<Object?> Function(HttpPlanner) call) async {
  final seen = <http.Request>[];
  await call(_answering(202, _building, seen));
  return seen.single;
}

void main() {
  test('every call the app makes is in the contract', () async {
    for (final MapEntry(key: name, value: call) in _calls.entries) {
      final r = await _send(call);
      expect(
        _operation(r),
        isNotNull,
        reason: '$name sends ${r.method} ${r.url.path}',
      );
    }
  });

  test('every call sends the app key the contract names', () async {
    final scheme = _map(
      _map(_map(_contract['components'])['securitySchemes'])['appKey'],
    );
    for (final call in _calls.values) {
      final r = await _send(call);
      expect(r.headers[scheme['name']], 'key');
    }
  });

  test(
    'a brief carries every field a plan request requires, and no other',
    () async {
      final body = (jsonDecode((await _send(_calls['start']!)).body) as Map)
          .keys
          .cast<String>()
          .toSet();
      expect(
        body.containsAll(_required('PlanRequest')),
        isTrue,
        reason: '$body',
      );
      expect(
        _properties('PlanRequest').containsAll(body),
        isTrue,
        reason: '$body',
      );
    },
  );

  test(
    'a swap carries every field a swap request requires, and no other',
    () async {
      for (final name in ['swap', 'swap without a note']) {
        final body = (jsonDecode((await _send(_calls[name]!)).body) as Map).keys
            .cast<String>()
            .toSet();
        expect(
          body.containsAll(_required('SwapRequest')),
          isTrue,
          reason: '$name: $body',
        );
        expect(
          _properties('SwapRequest').containsAll(body),
          isTrue,
          reason: '$name: $body',
        );
      }
    },
  );

  test(
    'every refusal the contract lists has its own meaning in the app',
    () async {
      for (final MapEntry(key: name, value: call) in _calls.entries) {
        final (path, op) = _operation(await _send(call))!;
        for (final code in _map(op['responses']).keys.map(int.parse)) {
          if (code < 300) continue;
          final body = code == 400
              ? {
                  'problems': ['x'],
                }
              : {'message': 'x'};
          await expectLater(
            call(_answering(code, body)),
            throwsA(
              isA<PlannerException>().having(
                (e) => e.kind,
                '$name: $code from $path',
                isNot(PlannerErrorKind.badResponse),
              ),
            ),
          );
        }
      }
    },
  );

  test('every success the contract lists reads as a plan', () async {
    for (final MapEntry(key: name, value: call) in _calls.entries) {
      final (path, op) = _operation(await _send(call))!;
      for (final code in _map(op['responses']).keys.map(int.parse)) {
        if (code >= 300) continue;
        expect(
          await call(_answering(code, _building)),
          isA<PlanSnapshot>(),
          reason: '$name: $code from $path',
        );
      }
    }
  });

  test('the app knows every value the contract can send', () {
    Set<String> names(List<Enum> values) => {for (final v in values) v.name};
    expect(_enum('PlanStatus'), names(PlanStatus.values));
    expect(_enum('Weekday'), names(Weekday.values));
    expect(_enum('Slot'), names(MealSlot.values));
    expect(_enum('Goal'), names(Goal.values));
    expect(_enum('Kind'), names(GroceryKind.values));
    expect(_enum('Unit'), names(IngredientUnit.values));
  });
}
