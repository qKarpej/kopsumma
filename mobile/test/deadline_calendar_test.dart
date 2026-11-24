import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kopsumma/api/models.dart';
import 'package:kopsumma/reminders/deadline_calendar.dart';

final q4 = Deadline(
  periods: const ['2026-Q3', '2026-Q4'],
  kind: 'deklaresana_un_samaksa',
  date: DateTime(2027, 1, 15),
  taxCents: 6039,
  taxableCents: 23683,
  provisional: true,
  past: false,
);

void main() {
  test('atgādinājumi: 7 dienas, 1 diena un termiņa dienā plkst. 9:00; pagājušie izlaisti', () {
    expect(reminderTimes(q4, DateTime(2026, 11, 24)),
        [DateTime(2027, 1, 8, 9), DateTime(2027, 1, 14, 9), DateTime(2027, 1, 15, 9)]);
    expect(reminderTimes(q4, DateTime(2027, 1, 10)), [DateTime(2027, 1, 14, 9), DateTime(2027, 1, 15, 9)]);
    expect(reminderTimes(q4, DateTime(2027, 1, 15, 10)), isEmpty);
  });

  test('atgādinājuma teksts ar summu', () {
    expect(reminderText(q4, DateTime(2027, 1, 14, 9)), 'Deklarēt un samaksāt nodokli rīt · 60,39 €');
    expect(reminderText(q4, DateTime(2027, 1, 8, 9)),
        'Deklarēt un samaksāt nodokli pēc 7 dienām (15.01.2027.) · 60,39 €');
  });

  test('Google kalendāra saite: visas dienas notikums', () {
    final url = googleCalendarUrl(q4);
    expect(url.host, 'calendar.google.com');
    expect(url.queryParameters['dates'], '20270115/20270116');
    expect(url.queryParameters['text'], 'Kopsumma: deklarēt un samaksāt nodokli');
    expect(url.queryParameters['details'], contains('III ceturksnis 2026, IV ceturksnis 2026'));
    expect(url.queryParameters['details'], contains('provizoriska'));
  });

  test('.ics atbilst RFC 5545: CRLF, rindas ≤ 75 baiti, atgādinājumi', () {
    final ics = buildIcs([q4], now: DateTime.utc(2026, 11, 24, 12));
    expect(ics, startsWith('BEGIN:VCALENDAR\r\n'));
    expect(ics, endsWith('END:VCALENDAR\r\n'));
    expect(ics, contains('DTSTART;VALUE=DATE:20270115\r\n'));
    expect(ics, contains('UID:2027-01-15-deklaresana_un_samaksa@kopsumma.lv'));
    expect(ics, contains('TRIGGER:-PT15H'));
    expect(ics, contains('TRIGGER:-P6DT15H'));
    expect(ics, contains(r'60\,39 €'));
    for (final line in ics.split('\r\n')) {
      expect(utf8.encode(line).length, lessThanOrEqualTo(75), reason: line);
    }
    final unfolded = ics.replaceAll('\r\n ', '');
    expect(unfolded, contains('DESCRIPTION:III ceturksnis 2026\\, IV ceturksnis 2026.'));
  });
}
