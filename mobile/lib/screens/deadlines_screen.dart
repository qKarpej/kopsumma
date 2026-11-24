import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../api/models.dart';
import '../money/money_format.dart';
import '../platform/download.dart';
import '../reminders/deadline_calendar.dart';
import '../reminders/sync.dart';
import '../state/app_scope.dart';
import '../theme/app_theme.dart';
import '../widgets/async_view.dart';

/// S-14 Nodokļa termiņi: atgādinājumi telefonā un pievienošana kalendāram (FR-15, FR-16).
class DeadlinesScreen extends StatelessWidget {
  const DeadlinesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final api = AppScope.apiOf(context);
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text('Termiņi un atgādinājumi', style: text.titleLarge)),
      body: SafeArea(
        child: AsyncView<Deadlines>(
          load: api.deadlines,
          isEmpty: (d) => d.isEmpty,
          empty: (_) => const EmptyState(
            icon: Icons.event_available_outlined,
            title: 'Termiņu vēl nav',
            message: 'Kad importēsiet izrakstu ar ienākumiem, šeit parādīsies deklarēšanas un samaksas termiņi.',
          ),
          ready: (context, d, reload) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _ReminderToggle(deadlines: d),
              const SizedBox(height: 16),
              if (d.upcoming.isNotEmpty) ...[
                Text('Nākamie', style: text.titleMedium),
                const SizedBox(height: 8),
                for (final x in d.upcoming) _DeadlineTile(deadline: x),
                if (canDownload) ...[
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    key: const Key('download-ics'),
                    onPressed: () => downloadFile(
                        utf8.encode(buildIcs(d.upcoming)), 'kopsumma-termini.ics', 'text/calendar'),
                    icon: const Icon(Icons.download),
                    label: const Text('Lejupielādēt kalendāra failu (.ics)'),
                  ),
                ],
              ],
              if (d.items.any((x) => x.past)) ...[
                const SizedBox(height: 20),
                Text('Pagājušie', style: text.titleMedium),
                const SizedBox(height: 8),
                for (final x in d.items.where((x) => x.past).toList().reversed) _DeadlineTile(deadline: x),
              ],
              const SizedBox(height: 16),
              Text(
                'Ja ceturkšņa ienākums sasniedz 1000 €, deklarē līdz nākamā mēneša 15. datumam un maksā līdz 23. datumam; '
                'citādi — gada deklarācijā līdz 15. janvārim. Aprēķins ir informatīvs.',
                style: text.labelSmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeadlineTile extends StatelessWidget {
  const _DeadlineTile({required this.deadline});

  final Deadline deadline;

  Future<void> _addToCalendar(BuildContext context) async {
    final ok = await launchUrl(googleCalendarUrl(deadline), mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kalendāru neizdevās atvērt.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final d = deadline;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
      decoration: BoxDecoration(
        color: d.past ? AppColors.surface2 : AppColors.warnBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(formatDate(d.date),
                style: text.titleMedium?.copyWith(color: d.past ? AppColors.muted : AppColors.warn)),
            Text(d.action, style: text.bodyLarge),
            Text(
              '${d.periods.map(formatPeriod).join(', ')} · ${formatCents(d.taxCents)}'
              '${d.provisional ? ' · provizoriski' : ''}',
              style: text.bodyMedium,
            ),
          ]),
        ),
        if (!d.past)
          IconButton(
            key: Key('calendar-${d.key}'),
            tooltip: 'Pievienot kalendāram',
            onPressed: () => _addToCalendar(context),
            icon: const Icon(Icons.event, color: AppColors.primary),
          ),
      ]),
    );
  }
}

class _ReminderToggle extends StatefulWidget {
  const _ReminderToggle({required this.deadlines});

  final Deadlines deadlines;

  @override
  State<_ReminderToggle> createState() => _ReminderToggleState();
}

class _ReminderToggleState extends State<_ReminderToggle> {
  bool? _on;
  bool _busy = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_on == null) {
      AppScope.of(context).settings.remindersOn().then((v) {
        if (mounted) setState(() => _on = v);
      });
    }
  }

  Future<void> _toggle(bool value) async {
    final services = AppScope.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    await services.settings.setRemindersOn(value);
    String message;
    if (value) {
      final n = await syncReminders(services);
      message = n > 0
          ? 'Ieplānoti $n atgādinājumi (7 dienas, 1 dienu iepriekš un termiņa dienā, plkst. 9:00).'
          : 'Atgādinājumus neizdevās ieplānot — pārbaudiet paziņojumu atļauju.';
      if (n == 0) await services.settings.setRemindersOn(false);
      value = n > 0;
    } else {
      await services.reminders.cancelAll();
      message = 'Atgādinājumi izslēgti.';
    }
    if (!mounted) return;
    setState(() {
      _on = value;
      _busy = false;
    });
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final text = Theme.of(context).textTheme;
    if (!services.reminders.supported) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: AppColors.surface2, borderRadius: BorderRadius.circular(12)),
        child: Text(
          'Paziņojumi pārlūkā netiek ieplānoti. Pievienojiet termiņus kalendāram — tas atgādinās arī telefonā.',
          style: text.bodyMedium,
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(12)),
      child: Column(children: [
        SwitchListTile(
          key: const Key('reminders-switch'),
          title: const Text('Atgādinājumi telefonā'),
          subtitle: const Text('7 dienas un 1 dienu pirms termiņa, plkst. 9:00'),
          value: _on ?? false,
          onChanged: _on == null || _busy ? null : _toggle,
        ),
        if (_on ?? false)
          TextButton(
            key: const Key('reminders-test'),
            onPressed: () => services.reminders.showTest(widget.deadlines.next),
            child: const Text('Parādīt atgādinājuma piemēru'),
          ),
      ]),
    );
  }
}
