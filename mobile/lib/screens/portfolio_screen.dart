import 'package:flutter/material.dart';

import '../api/models.dart';
import '../money/money_format.dart';
import '../routes.dart';
import '../state/app_scope.dart';
import '../theme/app_theme.dart';
import '../widgets/async_view.dart';

/// S-03 Portfelis — vertikālās šķēles galvenais ekrāns ar četriem stāvokļiem.
class PortfolioScreen extends StatelessWidget {
  const PortfolioScreen({super.key, this.onOpenTax});

  final VoidCallback? onOpenTax;

  static const _colors = [AppColors.primary, AppColors.series2, AppColors.muted, AppColors.line];

  @override
  Widget build(BuildContext context) {
    final api = AppScope.apiOf(context);
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text('Portfelis', style: text.headlineMedium),
        ),
        Expanded(
          child: AsyncView<Portfolio>(
            load: api.portfolio,
            isEmpty: (p) => p.isEmpty,
            empty: (_) => const EmptyState(
              icon: Icons.description_outlined,
              title: 'Vēl nav neviena darījuma',
              message: 'Importējiet izrakstu no Mintos vai Twino, un šeit būs redzama kopējā portfeļa vērtība.',
            ),
            ready: (context, p, reload) => RefreshIndicator(
              onRefresh: reload,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                children: [
                  Text('Kopējā vērtība · ${p.platforms.length} platformas', style: text.bodyMedium),
                  const SizedBox(height: 2),
                  Text(formatCents(p.totalCents), key: const Key('total'), style: text.displaySmall),
                  const SizedBox(height: 4),
                  Text.rich(TextSpan(style: text.bodyMedium, children: [
                    const TextSpan(text: 'Ienākumi šajā ceturksnī '),
                    TextSpan(
                      text: formatCents(p.quarterIncomeCents, signed: true),
                      style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.w700),
                    ),
                  ])),
                  const SizedBox(height: 12),
                  _ShareBar(platforms: p.platforms, total: p.totalCents, colors: _colors),
                  const SizedBox(height: 8),
                  for (final (i, pl) in p.platforms.indexed)
                    _PlatformRow(
                      platform: pl,
                      percent: sharePercent(pl.cents, p.totalCents),
                      color: _colors[i % _colors.length],
                      onTap: () => Navigator.of(context).pushNamed(Routes.transactions, arguments: pl.name),
                    ),
                  if (p.tax != null) ...[
                    const SizedBox(height: 20),
                    _TaxCard(tax: p.tax!, onTap: onOpenTax),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ShareBar extends StatelessWidget {
  const _ShareBar({required this.platforms, required this.total, required this.colors});

  final List<PlatformShare> platforms;
  final int total;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(
        height: 12,
        child: Row(
          children: [
            for (final (i, p) in platforms.indexed)
              Expanded(
                flex: total == 0 ? 1 : (p.cents * 1000 ~/ total).clamp(1, 1000),
                child: Container(
                  margin: EdgeInsets.only(right: i == platforms.length - 1 ? 0 : 2),
                  color: colors[i % colors.length],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PlatformRow extends StatelessWidget {
  const _PlatformRow({required this.platform, required this.percent, required this.color, required this.onTap});

  final PlatformShare platform;
  final int percent;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final count = platform.count == 1 ? '1 darījums' : '${platform.count} darījumi';
    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 64),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.line))),
        child: Row(
          children: [
            Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(platform.name, style: text.bodyLarge?.copyWith(fontWeight: FontWeight.w700)),
                  Text('$percent % · $count', style: text.bodyMedium),
                ],
              ),
            ),
            Text(formatCents(platform.cents), style: text.bodyLarge?.copyWith(fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class _TaxCard extends StatelessWidget {
  const _TaxCard({required this.tax, this.onTap});

  final TaxPreview tax;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Material(
      color: AppColors.surface2,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        key: const Key('tax-card'),
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(child: Text('Nodoklis · ${formatPeriod(tax.period)}', style: text.titleMedium)),
                const Icon(Icons.chevron_right, color: AppColors.muted),
              ]),
              const SizedBox(height: 6),
              Text(formatCents(tax.cents), style: text.displaySmall?.copyWith(fontSize: 28)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: AppColors.warnBg, borderRadius: BorderRadius.circular(10)),
                child: Text(
                  'Jādeklarē līdz ${formatDate(tax.deadline)}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.warn),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
