import 'package:flutter/material.dart';

import '../api/models.dart';
import '../money/money_format.dart';
import '../routes.dart';
import '../state/app_scope.dart';
import '../theme/app_theme.dart';

/// Nākamais nodokļa termiņš portfelī; pieskāriens atver termiņu un atgādinājumu ekrānu.
class NextDeadlineCard extends StatefulWidget {
  const NextDeadlineCard({super.key});

  @override
  State<NextDeadlineCard> createState() => _NextDeadlineCardState();
}

class _NextDeadlineCardState extends State<NextDeadlineCard> {
  Future<Deadlines>? _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= AppScope.apiOf(context).deadlines();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return FutureBuilder<Deadlines>(
      future: _future,
      builder: (context, snap) {
        final next = snap.data?.next;
        if (next == null) return const SizedBox.shrink(); // kļūda vai nav termiņu — portfelis strādā tāpat
        final days = DateUtils.dateOnly(next.date).difference(DateUtils.dateOnly(DateTime.now())).inDays;
        return Material(
          color: AppColors.warnBg,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            key: const Key('next-deadline'),
            borderRadius: BorderRadius.circular(16),
            onTap: () => Navigator.of(context).pushNamed(Routes.deadlines),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(children: [
                const Icon(Icons.notifications_active_outlined, color: AppColors.warn),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Nākamais termiņš · ${formatDate(next.date)}',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.warn)),
                    Text(
                      '${next.action} · ${formatCents(next.taxCents)}'
                      '${days >= 0 ? ' · pēc $days d.' : ''}',
                      style: text.bodyMedium?.copyWith(color: AppColors.warn),
                    ),
                  ]),
                ),
                const Icon(Icons.chevron_right, color: AppColors.warn),
              ]),
            ),
          ),
        );
      },
    );
  }
}
