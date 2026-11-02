import 'package:flutter_test/flutter_test.dart';
import 'package:kopsumma/money/money_format.dart';
import 'package:kopsumma/screens/tax_screen.dart';

const nb = ' ';

void main() {
  group('formatCents (naudas attēlošana)', () {
    test('tūkstošu atdalītājs un divi cipari aiz komata', () {
      expect(formatCents(1938000), '19${nb}380,00$nb€');
      expect(formatCents(124186012), '1${nb}241${nb}860,12$nb€');
      expect(formatCents(5), '0,05$nb€');
    });

    test('zīme: ienākums ar +, izdevums ar mīnusa zīmi', () {
      expect(formatCents(412, signed: true), '+4,12$nb€');
      expect(formatCents(-25000, signed: true), '−250,00$nb€');
      expect(formatCents(0, signed: true), '0,00$nb€');
    });

    test('citas valūtas paliek savā valūtā', () {
      expect(formatCents(305, currency: 'USD', signed: true), '+3,05$nb\$');
      expect(formatCents(100, currency: 'GBP'), '1,00${nb}GBP');
    });
  });

  group('procenti un daļas', () {
    test('likme bāzes punktos', () {
      expect(formatPercentBp(2550), '25,5$nb%');
      expect(formatPercentBp(2000), '20$nb%');
      expect(formatPercentBp(2505), '25,05$nb%');
    });

    test('sadalījuma procenti noapaļoti half-up un kopā ~100', () {
      expect(sharePercent(1241860, 1938000), 64);
      expect(sharePercent(696140, 1938000), 36);
      expect(sharePercent(1, 2), 50);
      expect(sharePercent(10, 0), 0);
    });
  });

  group('periodi un datumi', () {
    test('pēdējais pilnais ceturksnis', () {
      expect(lastCompletedQuarter(DateTime(2026, 11, 2)), '2026-Q3');
      expect(lastCompletedQuarter(DateTime(2027, 2, 1)), '2026-Q4');
      expect(previousQuarter('2026-Q1'), '2025-Q4');
    });

    test('formāti', () {
      expect(formatPeriod('2026-Q3'), 'III ceturksnis 2026');
      expect(formatDate(DateTime(2026, 10, 15)), '15.10.2026.');
      expect(formatShortDate(DateTime(2026, 9, 3)), '03.09.');
    });
  });
}
