import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../api/models.dart';
import '../routes.dart';
import '../state/app_scope.dart';
import '../theme/app_theme.dart';
import '../widgets/async_view.dart';
import '../widgets/form_parts.dart';
import 'import_result_screen.dart';

const platformHelp = {
  'Mintos': 'Mintos tīmekļa vietnē: Konts → Konta izraksts → izvēlieties periodu → Lejupielādēt CSV.',
  'Twino': 'Twino tīmekļa vietnē: Mans konts → Konta izraksts → izvēlieties periodu → Eksportēt CSV.',
};

/// S-04 platformas izvēle un S-05 faila izvēle. Augšupielāde neko nesaglabā — tikai pārbauda (API-05).
class ImportScreen extends StatefulWidget {
  const ImportScreen({super.key, this.initialPlatformId});

  final int? initialPlatformId;

  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  late int? _platformId = widget.initialPlatformId;
  bool _busy = false;
  String? _error;

  Future<void> _pickAndUpload(PlatformInfo platform) async {
    final services = AppScope.of(context);
    setState(() => _error = null);
    final file = await services.files.pickStatement();
    if (file == null || !mounted) return;
    setState(() => _busy = true);
    try {
      final preview = await services.api
          .uploadStatement(platformId: platform.id, fileName: file.name, bytes: file.bytes);
      if (!mounted) return;
      await Navigator.of(context).pushNamed(Routes.importPreview, arguments: preview);
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.code == 'IMPORT_INVALID_ROW' || e.status == 422) {
        await Navigator.of(context).pushNamed(Routes.importError,
            arguments: ImportFailure(message: e.message, row: e.row, fileName: file.name, platformId: platform.id));
      } else {
        setState(() => _error = e.message);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final api = AppScope.apiOf(context);
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text('Importēt izrakstu', style: text.titleLarge)),
      body: SafeArea(
        child: AsyncView<List<PlatformInfo>>(
          load: api.platforms,
          isEmpty: (p) => p.isEmpty,
          empty: (_) => const EmptyState(
              icon: Icons.account_balance_outlined, title: 'Nav platformu', message: 'Serverī nav konfigurētu platformu.'),
          ready: (context, platforms, _) {
            final selected = platforms.where((p) => p.id == _platformId && p.active).firstOrNull;
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text('1. Izvēlieties platformu', style: text.titleMedium),
                const SizedBox(height: 8),
                for (final p in platforms)
                  _PlatformTile(
                    platform: p,
                    selected: p.id == _platformId,
                    onTap: p.active && !_busy ? () => setState(() => _platformId = p.id) : null,
                  ),
                const SizedBox(height: 20),
                Text('2. Izvēlieties izraksta failu (CSV)', style: text.titleMedium),
                const SizedBox(height: 8),
                if (selected != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: AppColors.surface2, borderRadius: BorderRadius.circular(12)),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Icon(Icons.info_outline, size: 20, color: AppColors.muted),
                      const SizedBox(width: 8),
                      Expanded(child: Text(platformHelp[selected.name] ?? 'Lejupielādējiet konta izrakstu CSV formātā.',
                          style: text.bodyMedium)),
                    ]),
                  )
                else
                  Text('Vispirms izvēlieties platformu.', style: text.bodyMedium),
                const SizedBox(height: 8),
                Text('Fails netiek saglabāts, kamēr neapstiprināsiet pārbaudes rezultātu.', style: text.labelSmall),
                if (_error != null) ...[const SizedBox(height: 12), FieldError(_error!)],
                const SizedBox(height: 20),
                FilledButton.icon(
                  key: const Key('pick-file'),
                  onPressed: selected == null || _busy ? null : () => _pickAndUpload(selected),
                  icon: _busy ? const SizedBox.shrink() : const Icon(Icons.upload_file),
                  label: BusyLabel(busy: _busy, label: 'Izvēlēties failu'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PlatformTile extends StatelessWidget {
  const _PlatformTile({required this.platform, required this.selected, this.onTap});

  final PlatformInfo platform;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected ? AppColors.primaryWeak : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: selected ? AppColors.primary : AppColors.line, width: selected ? 2 : 1),
        ),
        child: InkWell(
          key: Key('platform-${platform.name}'),
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            child: Row(children: [
              Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off,
                  color: platform.active ? AppColors.primary : AppColors.line),
              const SizedBox(width: 12),
              Expanded(
                child: Text(platform.name,
                    style: text.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w700, color: platform.active ? AppColors.ink : AppColors.muted)),
              ),
              if (!platform.active) Text('drīzumā', style: text.labelSmall),
            ]),
          ),
        ),
      ),
    );
  }
}
