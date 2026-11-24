import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../api/models.dart';
import '../money/money_format.dart';
import '../reminders/sync.dart';
import '../routes.dart';
import '../state/app_scope.dart';
import '../theme/app_theme.dart';
import '../widgets/form_parts.dart';
import 'import_result_screen.dart';

/// S-06 Pārbaudes rezultāts: ko imports saglabās. Saglabā tikai pēc apstiprinājuma (API-06).
class ImportPreviewScreen extends StatefulWidget {
  const ImportPreviewScreen({super.key, required this.preview});

  final ImportPreview preview;

  @override
  State<ImportPreviewScreen> createState() => _ImportPreviewScreenState();
}

class _ImportPreviewScreenState extends State<ImportPreviewScreen> {
  bool _saving = false;
  String? _error;

  ImportPreview get p => widget.preview;

  Future<void> _confirm() async {
    final services = AppScope.of(context);
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final result = await services.api.confirmImport(p.id);
      await syncReminders(services);
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(Routes.importDone, arguments: ImportDone(result: result, preview: p));
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _cancel() async {
    try {
      await AppScope.apiOf(context).cancelImport(p.id);
    } on ApiException {
      // atcelšana nav kritiska — dati netiek saglabāti bez apstiprinājuma
    }
    if (mounted) Navigator.of(context).pushNamedAndRemoveUntil(Routes.home, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text('Pārbaude', style: text.titleLarge)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('${p.platform} · ${p.fileName}', style: text.bodyMedium),
            if (p.from != null && p.to != null)
              Text('Periods: ${formatDate(p.from!)} – ${formatDate(p.to!)}', style: text.bodyMedium),
            const SizedBox(height: 12),
            Text(p.nothingNew ? 'Nav jaunu darījumu' : '${p.newCount} jauni darījumi',
                key: const Key('preview-new'), style: text.displaySmall?.copyWith(fontSize: 30)),
            const SizedBox(height: 12),
            _Line('Rindas failā', '${p.rows}'),
            _Line('Jauni darījumi', '${p.newCount}'),
            _Line('Jau saglabāti (dublikāti)', '${p.duplicates}', hint: 'netiks pievienoti otrreiz'),
            if (p.skipped > 0) _Line('Iemaksas un izmaksas', '${p.skipped}', hint: 'nav ieguldījumi — izlaisti'),
            _Line('Procentu un kapitāla ienākums', formatCents(p.incomeCents)),
            const SizedBox(height: 16),
            if (_error != null) ...[FieldError(_error!), const SizedBox(height: 12)],
            if (p.nothingNew)
              FilledButton(
                key: const Key('preview-home'),
                onPressed: _cancel,
                child: const Text('Uz portfeli'),
              )
            else ...[
              FilledButton(
                key: const Key('preview-save'),
                onPressed: _saving ? null : _confirm,
                child: BusyLabel(busy: _saving, label: 'Saglabāt ${p.newCount} darījumus'),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                key: const Key('preview-cancel'),
                onPressed: _saving ? null : _cancel,
                child: const Text('Atcelt'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line(this.label, this.value, {this.hint});

  final String label;
  final String value;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.line))),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: text.bodyLarge?.copyWith(color: AppColors.muted)),
            if (hint != null) Text(hint!, style: text.labelSmall),
          ]),
        ),
        Text(value, style: text.bodyLarge?.copyWith(fontWeight: FontWeight.w700)),
      ]),
    );
  }
}
