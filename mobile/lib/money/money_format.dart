/// Summu un datumu attēlošana pēc K2 principiem. Ievade vienmēr veselos centos.
const _nbsp = ' ';
const _minus = '−';

String formatCents(int cents, {String currency = 'EUR', bool signed = false}) {
  final negative = cents < 0;
  final abs = cents.abs();
  final whole = (abs ~/ 100).toString();
  final fraction = (abs % 100).toString().padLeft(2, '0');
  final grouped = StringBuffer();
  for (var i = 0; i < whole.length; i++) {
    if (i > 0 && (whole.length - i) % 3 == 0) grouped.write(_nbsp);
    grouped.write(whole[i]);
  }
  final symbol = switch (currency) {
    'EUR' => '€',
    'USD' => r'$',
    _ => currency,
  };
  final sign = negative ? _minus : (signed && cents > 0 ? '+' : '');
  return '$sign$grouped,$fraction$_nbsp$symbol';
}

String formatPercentBp(int basisPoints) {
  final whole = basisPoints ~/ 100;
  final rest = basisPoints % 100;
  if (rest == 0) return '$whole$_nbsp%';
  final decimals = rest % 10 == 0 ? (rest ~/ 10).toString() : rest.toString().padLeft(2, '0');
  return '$whole,$decimals$_nbsp%';
}

/// Daļa procentos no kopsummas, noapaļota līdz veselam (sadalījuma joslai).
int sharePercent(int partCents, int totalCents) {
  if (totalCents <= 0) return 0;
  return ((partCents * 100 * 2 + totalCents) ~/ (totalCents * 2));
}

String formatShortDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.';

String formatDate(DateTime d) => '${formatShortDate(d)}${d.year}.';

/// '2026-Q3' → 'III ceturksnis 2026'
String formatPeriod(String period) {
  final parts = period.split('-Q');
  const roman = ['I', 'II', 'III', 'IV'];
  final q = int.tryParse(parts.length == 2 ? parts[1] : '') ?? 0;
  if (q < 1 || q > 4) return period;
  return '${roman[q - 1]} ceturksnis ${parts[0]}';
}
