import 'package:flutter/material.dart';

import '../api/models.dart';
import '../money/money_format.dart';
import '../state/app_scope.dart';
import '../theme/app_theme.dart';
import '../widgets/async_view.dart';

/// Pēdējais pilnais ceturksnis, piem. 02.11.2026 → '2026-Q3'.
String lastCompletedQuarter(DateTime now) {
  final q = (now.month - 1) ~/ 3 + 1;
  return q == 1 ? '${now.year - 1}-Q4' : '${now.year}-Q${q - 1}';
}

String previousQuarter(String period) {
  final parts = period.split('-Q');
  final y = int.parse(parts[0]);
  final q = int.parse(parts[1]);
  return q == 1 ? '${y - 1}-Q4' : '$y-Q${q - 1}';
}

/// S-12 Nodoklis.
class TaxScreen extends StatefulWidget {
  const TaxScreen({super.key, this.now});

  final DateTime? now;

  @override
  State<TaxScreen> createState() => _TaxScreenState();
}

class _TaxScreenState extends State<TaxScreen> {
  late final String _latest = lastCompletedQuarter(widget.now ?? DateTime.now());
  late String _period = _latest;

  @override
  Widget build(BuildContext context) {
    final api = AppScope.apiOf(context);
    final text = Theme.of(context).textTheme;
    final periods = [_latest, previousQuarter(_latest)];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Text('Nodoklis', style: text.headlineMedium),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Wrap(
            spacing: 8,
            children: [
              for (final p in periods)
                ChoiceChip(
                  label: Text(formatPeriod(p)),
                  selected: _period == p,
                  onSelected: (_) => setState(() => _period = p),
                ),
            ],
          ),
        ),
        Expanded(
          child: AsyncView<TaxSummary>(
            key: ValueKey(_period),
            load: () => api.tax(_period),
            isEmpty: (t) => t.isEmpty,
            empty: (_) => const EmptyState(
              icon: Icons.percent,
              title: 'Šajā periodā nav apliekamu ienākumu',
              message: 'Kad importēsiet izrakstu ar procentiem vai kapitāla pieaugumu, šeit būs aprēķins.',
            ),
            ready: (context, t, _) => ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              children: [
                Text('Aprēķinātais nodoklis', style: text.bodyMedium),
                Text(formatCents(t.taxCents), key: const Key('tax-total'), style: text.displaySmall),
                Text(
                  '${formatPercentBp(t.rateBp)} no apliekamā ienākuma ${formatCents(t.taxableCents)}',
                  style: text.bodyMedium,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppColors.warnBg, borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.event_outlined, color: AppColors.warn, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Jādeklarē līdz ${formatDate(t.declareBy)}',
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.warn)),
                            Text('Nodoklis jāsamaksā līdz ${formatDate(t.payBy)}.',
                                style: const TextStyle(fontSize: 14, color: AppColors.warn)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                _Row('Procentu ienākums', formatCents(t.interestCents)),
                _Row('Kapitāla pieaugums', formatCents(t.capitalGainCents)),
                if (t.excluded > 0) _Row('Nav iekļauts (jāpārbauda)', '${t.excluded} darījums'),
                const SizedBox(height: 12),
                Text('Aprēķins ir informatīvs un neaizstāj VID norādes. Deklarāciju iesniedz EDS.',
                    style: text.labelSmall),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.line))),
      child: Row(children: [
        Expanded(child: Text(label, style: text.bodyLarge?.copyWith(color: AppColors.muted))),
        Text(value, style: text.bodyLarge?.copyWith(fontWeight: FontWeight.w700)),
      ]),
    );
  }
}
