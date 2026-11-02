import 'package:flutter/material.dart';

import '../api/models.dart';
import '../money/money_format.dart';
import '../routes.dart';
import '../state/app_scope.dart';
import '../theme/app_theme.dart';
import '../widgets/async_view.dart';

/// S-10 Darījumi ar platformas filtru.
class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key, this.platform, this.standalone = false});

  final String? platform;
  final bool standalone;

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  late String? _platform = widget.platform;

  @override
  Widget build(BuildContext context) {
    final api = AppScope.apiOf(context);
    final text = Theme.of(context).textTheme;
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!widget.standalone)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Text('Darījumi', style: text.headlineMedium),
          ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(
            children: [
              for (final p in const [null, 'Mintos', 'Twino'])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(p ?? 'Visi'),
                    selected: _platform == p,
                    onSelected: (_) => setState(() => _platform = p),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: AsyncView<List<Tx>>(
            key: ValueKey(_platform),
            load: () => api.transactions(platform: _platform),
            isEmpty: (items) => items.isEmpty,
            empty: (_) => const EmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'Nav darījumu',
              message: 'Šim filtram vēl nav importētu darījumu.',
            ),
            ready: (context, items, reload) {
              final review = items.where((t) => t.needsReview).length;
              return RefreshIndicator(
                onRefresh: reload,
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    Text(
                      '${items.length} darījumi${review > 0 ? ' · $review jāpārbauda' : ''}',
                      style: text.bodyMedium,
                    ),
                    const SizedBox(height: 4),
                    for (final t in items) TxRow(tx: t),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
    if (!widget.standalone) return body;
    return Scaffold(
      appBar: AppBar(title: Text(_platform ?? 'Darījumi', style: text.headlineMedium)),
      body: SafeArea(child: body),
    );
  }
}

class TxRow extends StatelessWidget {
  const TxRow({super.key, required this.tx});

  final Tx tx;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final positive = tx.cents > 0;
    return InkWell(
      onTap: () => Navigator.of(context).pushNamed(Routes.transaction, arguments: tx.id),
      child: Container(
        constraints: const BoxConstraints(minHeight: 64),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.line))),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tx.typeLabel, style: text.bodyLarge?.copyWith(fontWeight: FontWeight.w700)),
                  Text('${formatShortDate(tx.date)} · ${tx.platform}', style: text.bodyMedium),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatCents(tx.cents, currency: tx.currency, signed: true),
                  style: text.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: positive ? AppColors.success : AppColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                StatusBadge(needsReview: tx.needsReview),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.needsReview});

  final bool needsReview;

  @override
  Widget build(BuildContext context) {
    final fg = needsReview ? AppColors.warn : AppColors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: needsReview ? AppColors.warnBg : AppColors.primaryWeak,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(needsReview ? Icons.error_outline : Icons.check, size: 12, color: fg),
          const SizedBox(width: 4),
          Text(
            needsReview ? 'Jāpārbauda' : 'Importēts',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: fg),
          ),
        ],
      ),
    );
  }
}
