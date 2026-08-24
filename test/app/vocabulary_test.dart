import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// RideMate names cost sharing, never commerce.
///
/// The product facilitates shared journeys and legitimate journey-cost
/// sharing. It is not a taxi, it takes no payment, and it pays nobody. The
/// words a codebase uses for money decide how everyone who reads it later
/// thinks about the product, and a name outlives the comment that qualifies
/// it: `fareShare` survived from Phase 3 to Phase 10 underneath copy that
/// correctly said `Senin payın`, because nothing was watching the identifier.
///
/// The moment a name reaches a JSON body it stops being an internal choice and
/// becomes the contract other people build against. This guard exists so that
/// correction happens before that, not after.
///
/// The backend has the same rule over `openapi.yaml`. This is its client half.
///
/// WHY IDENTIFIERS ONLY
///
/// Comments and string literals are stripped before scanning, so this file and
/// the headers that explain the rule can name the words they forbid, and so a
/// message may honestly say that nobody is charged. The rule governs what
/// things are CALLED. A naive grep cannot tell a name from an explanation and
/// would make the rule unusable within a week of being written.
void main() {
  /// Whole tokens, not substrings.
  ///
  /// `costSharePerPerson` and `sharedRouteCount` are fine; `discharge` would
  /// be too. `driverEarnings` is not.
  const List<String> forbidden = <String>[
    'fare',
    'price',
    'pricing',
    'earnings',
    'income',
    'payout',
    'revenue',
    'charge',
    'commission',
    'invoice',
  ];

  /// Source with `//` comments and string literals removed.
  String identifiersOnly(String source) {
    final String withoutComments = source
        .split('\n')
        .map((String line) {
          final int comment = line.indexOf('//');

          return comment == -1 ? line : line.substring(0, comment);
        })
        .join('\n');

    return withoutComments
        .replaceAll(RegExp(r"'''(.|\n)*?'''"), "''")
        .replaceAll(RegExp(r'"""(.|\n)*?"""'), '""')
        .replaceAll(RegExp(r"'(\\.|[^'\\\n])*'"), "''")
        .replaceAll(RegExp(r'"(\\.|[^"\\\n])*"'), '""');
  }

  /// The forbidden whole-words inside one identifier, camelCase split first.
  Set<String> forbiddenTokensIn(String identifier) {
    final String snake = identifier.replaceAllMapped(
      RegExp('(?<=[a-z0-9])(?=[A-Z])'),
      (Match _) => '_',
    );

    return snake
        .toLowerCase()
        .split(RegExp('[^a-z0-9]+'))
        .where(forbidden.contains)
        .toSet();
  }

  Set<String> offendingIdentifiersIn(String source) {
    final Set<String> offenders = <String>{};

    for (final RegExpMatch match in RegExp(
      r'[A-Za-z_$][A-Za-z0-9_$]*',
    ).allMatches(identifiersOnly(source))) {
      final String identifier = match[0]!;
      if (forbiddenTokensIn(identifier).isNotEmpty) {
        offenders.add(identifier);
      }
    }

    return offenders;
  }

  group('Commercial vocabulary', () {
    test('no identifier in lib/ names a fare, a price or an income', () {
      final Map<String, Set<String>> offenders = <String, Set<String>>{};

      for (final File file
          in Directory('lib')
              .listSync(recursive: true)
              .whereType<File>()
              .where((File f) => f.path.endsWith('.dart'))) {
        final Set<String> found = offendingIdentifiersIn(
          file.readAsStringSync(),
        );
        if (found.isNotEmpty) {
          offenders[file.path] = found;
        }
      }

      expect(
        offenders,
        isEmpty,
        reason:
            'RideMate shares journey costs. It charges nobody, so nothing in '
            'it may be named as though it did. Use costSharePerPerson.',
      );
    });

    /// A guard nobody has seen fail is a guard nobody knows works.
    ///
    /// The camelCase split is the load-bearing part: without it `fareShare`
    /// reads as one token and passes, which is exactly the defect this file
    /// was written to retire.
    test('the guard catches the thing it bans', () {
      for (final String caught in <String>[
        'fareShare',
        'driverEarnings',
        'routeDetailsFareLabel',
        'calculatePrice',
        'monthlyRevenue',
        'payout_total',
      ]) {
        expect(
          offendingIdentifiersIn('final int $caught = 0;'),
          isNotEmpty,
          reason: caught,
        );
      }

      for (final String allowed in <String>[
        'costSharePerPerson',
        'sharedRouteCount',
        'discharge',
        'chargingStation',
        'commissioned',
      ]) {
        expect(
          offendingIdentifiersIn('final int $allowed = 0;'),
          isEmpty,
          reason: allowed,
        );
      }
    });

    /// Prose must stay free, or the rule cannot be explained where it applies.
    test('comments and copy may name what identifiers may not', () {
      expect(
        offendingIdentifiersIn('// This is not a fare and nobody is charged.'),
        isEmpty,
      );
      expect(
        offendingIdentifiersIn("const String s = 'No one is charged a fare.';"),
        isEmpty,
      );
    });
  });
}
