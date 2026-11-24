import 'package:flutter/material.dart';

import '../routes.dart';
import '../state/app_scope.dart';
import '../theme/app_theme.dart';
import '../widgets/server_dialog.dart';

/// S-13 Profils.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Future<String>? _email;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _email ??= AppScope.apiOf(context).currentEmail();
  }

  Future<void> _logout() async {
    final services = AppScope.of(context);
    final nav = Navigator.of(context);
    await services.reminders.cancelAll();
    await services.api.logout();
    nav.pushNamedAndRemoveUntil(Routes.start, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final text = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Profils', style: text.headlineMedium),
        const SizedBox(height: 8),
        FutureBuilder<String>(
          future: _email,
          builder: (_, snap) => Text(snap.data ?? '', key: const Key('profile-email'), style: text.bodyLarge),
        ),
        const SizedBox(height: 16),
        _Item(
          key: const Key('profile-imports'),
          icon: Icons.history,
          title: 'Importu vēsture',
          onTap: () => Navigator.of(context).pushNamed(Routes.importHistory),
        ),
        _Item(
          key: const Key('profile-deadlines'),
          icon: Icons.notifications_outlined,
          title: 'Termiņi un atgādinājumi',
          onTap: () => Navigator.of(context).pushNamed(Routes.deadlines),
        ),
        _Item(
          icon: Icons.dns_outlined,
          title: 'Servera adrese',
          subtitle: services.api.serverUrl,
          onTap: () async {
            await showServerDialog(context);
            if (mounted) setState(() {});
          },
        ),
        const SizedBox(height: 24),
        OutlinedButton(key: const Key('logout'), onPressed: _logout, child: const Text('Iziet')),
        const SizedBox(height: 16),
        Text('Kopsumma 0.2 · testa versija. Lietotne nepārskaita naudu un nesniedz deklarāciju VID.',
            style: text.labelSmall),
      ],
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({super.key, required this.icon, required this.title, this.subtitle, required this.onTap});

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(icon, color: AppColors.primary),
        title: Text(title),
        subtitle: subtitle == null ? null : Text(subtitle!),
        trailing: const Icon(Icons.chevron_right, color: AppColors.muted),
        onTap: onTap,
        shape: const Border(bottom: BorderSide(color: AppColors.line)),
      );
}
