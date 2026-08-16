import 'package:flutter_test/flutter_test.dart';
import 'package:ridemate/core/format/rm_text_conventions.dart';

void main() {
  group('Turkish-aware casing', () {
    test('dotted and dotless i follow Turkish rules, not Dart defaults', () {
      // Dart's toUpperCase() maps 'i' -> 'I', which is wrong in Turkish.
      expect('i'.toUpperCase(), 'I', reason: 'baseline Dart behaviour');
      expect(RmTextConventions.upperTr('i'), 'İ');
      expect(RmTextConventions.upperTr('ı'), 'I');
      expect(RmTextConventions.upperTr('irem'), 'İREM');
      expect(RmTextConventions.upperTr('ışık'), 'IŞIK');
    });

    test('lowercasing is the inverse', () {
      expect(RmTextConventions.lowerTr('İREM'), 'irem');
      expect(RmTextConventions.lowerTr('IŞIK'), 'ışık');
    });

    test('leaves other Turkish letters intact', () {
      expect(RmTextConventions.upperTr('çğöşü'), 'ÇĞÖŞÜ');
    });
  });

  group('Name abbreviation — a privacy default', () {
    test('shows first name plus surname initial', () {
      expect(RmTextConventions.abbreviateName('Selin Kaya'), 'Selin K.');
      expect(RmTextConventions.abbreviateName('Mert Aydın'), 'Mert A.');
      expect(RmTextConventions.abbreviateName('Emre Yılmaz'), 'Emre Y.');
    });

    test('uses the Turkish initial for a dotted i', () {
      expect(RmTextConventions.abbreviateName('Elif ilkay'), 'Elif İ.');
    });

    test('handles middle names by using the last one', () {
      expect(RmTextConventions.abbreviateName('Ayşe Nur Demir'), 'Ayşe D.');
    });

    test('fails closed on input it cannot parse', () {
      // Never guess at a surname: return the input untouched instead.
      expect(RmTextConventions.abbreviateName('Selin'), 'Selin');
      expect(RmTextConventions.abbreviateName(''), '');
      expect(RmTextConventions.abbreviateName('   '), '');
    });

    test('tolerates irregular whitespace', () {
      expect(RmTextConventions.abbreviateName('  Selin   Kaya  '), 'Selin K.');
    });
  });

  group('Avatar initials', () {
    test('takes the first letter of the first and last name', () {
      expect(RmTextConventions.initials('Selin Kaya'), 'SK');
      expect(RmTextConventions.initials('Elif Çelik'), 'EÇ');
      expect(RmTextConventions.initials('Ayşe Nur Demir'), 'AD');
    });

    test('falls back to a single letter', () {
      expect(RmTextConventions.initials('Selin'), 'S');
      expect(RmTextConventions.initials(''), '');
    });

    test('applies Turkish casing', () {
      expect(RmTextConventions.initials('irem ışık'), 'İI');
    });
  });

  group('Phone masking — must fail closed', () {
    test('masks a Turkish mobile number as the design shows', () {
      expect(RmTextConventions.maskPhone('+90 555 123 4542'), '+90 5•• ••• 42');
      expect(RmTextConventions.maskPhone('905551234542'), '+90 5•• ••• 42');
    });

    test('handles a national number without a country code', () {
      expect(RmTextConventions.maskPhone('5551234542'), '5•• ••• 42');
    });

    test('never reveals more than the first and last digits', () {
      const String number = '+90 555 123 4542';
      final String masked = RmTextConventions.maskPhone(number);
      // The interior digits must not survive anywhere in the output.
      expect(masked, isNot(contains('123')));
      expect(masked, isNot(contains('5551')));
      expect(masked.replaceAll(RegExp(r'[^0-9]'), '').length, lessThan(6));
    });

    test('fully masks input too short to mask safely', () {
      expect(RmTextConventions.maskPhone('12345'), '•••••');
      expect(RmTextConventions.maskPhone(''), '•••');
      expect(RmTextConventions.maskPhone('abc'), '•••');
    });
  });

  group('Vehicle plates', () {
    test('normalises a Turkish plate', () {
      expect(RmTextConventions.plate('34ABC128'), '34 ABC 128');
      expect(RmTextConventions.plate('34 abc 128'), '34 ABC 128');
      expect(RmTextConventions.plate('06 A 1234'), '06 A 1234');
    });

    test('does not mangle input that is not a Turkish plate', () {
      expect(RmTextConventions.plate('B-MW 1234'), 'B-MW 1234');
    });
  });

  group('Metadata joining', () {
    test('uses the design middle-dot separator', () {
      expect(
        RmTextConventions.joinMeta(<String>['Doğrulanmış', '128 yolculuk']),
        'Doğrulanmış · 128 yolculuk',
      );
    });

    test('drops missing values instead of leaving dangling separators', () {
      expect(
        RmTextConventions.joinMeta(<String?>['Doğrulanmış', null, '', '  ']),
        'Doğrulanmış',
      );
      expect(RmTextConventions.joinMeta(<String?>[null, null]), '');
    });
  });

  group('Route formatting', () {
    test('uses the design arrow', () {
      expect(RmTextConventions.route('Kadıköy', 'Levent'), 'Kadıköy → Levent');
    });
  });
}
