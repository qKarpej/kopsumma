import '../api/models.dart';
import '../money/money_format.dart';

/// Kalendāra notikumi un atgādinājumu laiki nodokļa termiņiem (FR-15, FR-16). Tīra loģika — bez spraudņiem.

String eventTitle(Deadline d) => 'Kopsumma: ${d.action.toLowerCase()}';

String eventDescription(Deadline d) {
  final periods = d.periods.map(formatPeriod).join(', ');
  final amount = d.taxCents > 0 ? 'Aprēķinātais nodoklis: ${formatCents(d.taxCents)}. ' : '';
  final note = d.provisional ? 'Summa ir provizoriska — ceturksnis vēl nav beidzies. ' : '';
  return '$periods. $amount${note}Deklarāciju iesniedz VID EDS (eds.vid.gov.lv).';
}

String _ymd(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}';

/// Google kalendāra saite ar aizpildītu visas dienas notikumu (der telefonā un pārlūkā).
Uri googleCalendarUrl(Deadline d) => Uri.https('calendar.google.com', '/calendar/render', {
      'action': 'TEMPLATE',
      'text': eventTitle(d),
      'dates': '${_ymd(d.date)}/${_ymd(d.date.add(const Duration(days: 1)))}',
      'details': eventDescription(d),
    });

String _escape(String s) =>
    s.replaceAll(r'\', r'\\').replaceAll(';', r'\;').replaceAll(',', r'\,').replaceAll('\n', r'\n');

/// RFC 5545 rindu locīšana pie 75 baitiem (UTF-8).
String _fold(String line) {
  final out = StringBuffer();
  var bytes = 0;
  for (final rune in line.runes) {
    final ch = String.fromCharCode(rune);
    final len = rune < 0x80 ? 1 : rune < 0x800 ? 2 : rune < 0x10000 ? 3 : 4;
    if (bytes + len > 75) {
      out.write('\r\n ');
      bytes = 1;
    }
    out.write(ch);
    bytes += len;
  }
  return out.toString();
}

/// .ics fails ar visiem nākamajiem termiņiem; katram — atgādinājumi 7 dienas un 1 dienu iepriekš.
String buildIcs(List<Deadline> deadlines, {DateTime? now}) {
  final stamp = (now ?? DateTime.now()).toUtc();
  final dtStamp = '${_ymd(stamp)}T${stamp.hour.toString().padLeft(2, '0')}'
      '${stamp.minute.toString().padLeft(2, '0')}${stamp.second.toString().padLeft(2, '0')}Z';
  final lines = <String>[
    'BEGIN:VCALENDAR',
    'VERSION:2.0',
    'PRODID:-//Kopsumma//Nodokla termini//LV',
    'CALSCALE:GREGORIAN',
    'METHOD:PUBLISH',
  ];
  for (final d in deadlines) {
    lines.addAll([
      'BEGIN:VEVENT',
      'UID:${d.key}@kopsumma.lv',
      'DTSTAMP:$dtStamp',
      'DTSTART;VALUE=DATE:${_ymd(d.date)}',
      'DTEND;VALUE=DATE:${_ymd(d.date.add(const Duration(days: 1)))}',
      'SUMMARY:${_escape(eventTitle(d))}',
      'DESCRIPTION:${_escape(eventDescription(d))}',
      // visas dienas notikums sākas 00:00 → −15 h = iepriekšējā dienā 9:00; −6 d 15 h = nedēļu iepriekš 9:00
      for (final trigger in const ['-P6DT15H', '-PT15H']) ...[
        'BEGIN:VALARM',
        'ACTION:DISPLAY',
        'DESCRIPTION:${_escape(eventTitle(d))}',
        'TRIGGER:$trigger',
        'END:VALARM',
      ],
      'END:VEVENT',
    ]);
  }
  lines.add('END:VCALENDAR');
  return '${lines.map(_fold).join('\r\n')}\r\n';
}

/// Atgādinājuma brīži: 7 dienas un 1 dienu pirms termiņa, kā arī termiņa dienā — plkst. 9:00.
/// Pagājušie brīži netiek ieplānoti.
List<DateTime> reminderTimes(Deadline d, DateTime now) {
  final day = DateTime(d.date.year, d.date.month, d.date.day, 9);
  return [7, 1, 0]
      .map((n) => day.subtract(Duration(days: n)))
      .where((t) => t.isAfter(now))
      .toList();
}

String reminderText(Deadline d, DateTime at) {
  final days = DateTime(d.date.year, d.date.month, d.date.day).difference(DateTime(at.year, at.month, at.day)).inDays;
  final when = switch (days) {
    0 => 'šodien',
    1 => 'rīt',
    _ => 'pēc $days dienām (${formatDate(d.date)})',
  };
  final amount = d.taxCents > 0 ? ' · ${formatCents(d.taxCents)}' : '';
  return '${d.action} $when$amount';
}
