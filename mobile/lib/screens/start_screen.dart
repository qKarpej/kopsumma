import 'package:flutter/material.dart';

import '../routes.dart';
import '../state/app_scope.dart';
import '../theme/app_theme.dart';
import '../widgets/server_dialog.dart';

/// S-01 Sākums. Ja ierīcē ir saglabāta sesija, lietotājs uzreiz nonāk portfelī.
class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _restore());
  }

  Future<void> _restore() async {
    var ok = false;
    try {
      ok = await AppScope.apiOf(context).restoreSession();
    } catch (_) {
      ok = false;
    }
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pushNamedAndRemoveUntil(Routes.home, (_) => false);
    } else {
      setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              const Align(alignment: Alignment.centerLeft, child: _Mark()),
              const SizedBox(height: 28),
              Text('Kopsumma', style: text.displaySmall?.copyWith(fontSize: 40)),
              const SizedBox(height: 12),
              Text(
                'Ieguldījumi no visām platformām un nodoklis par tiem — vienā skatā.',
                style: text.bodyLarge,
              ),
              const Spacer(),
              if (_checking)
                const Center(child: CircularProgressIndicator(key: Key('start-checking')))
              else ...[
                FilledButton(
                  key: const Key('start-login'),
                  onPressed: () => Navigator.of(context).pushNamed(Routes.login),
                  child: const Text('Pieteikties'),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  key: const Key('start-register'),
                  onPressed: () => Navigator.of(context).pushNamed(Routes.register),
                  child: const Text('Izveidot kontu'),
                ),
                const SizedBox(height: 4),
                TextButton(
                  key: const Key('start-server'),
                  onPressed: () => showServerDialog(context),
                  child: const Text('Servera adrese'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Mark extends StatelessWidget {
  const _Mark();

  @override
  Widget build(BuildContext context) {
    Widget bar(double h, Color c) => Container(
          width: 18,
          height: h,
          margin: const EdgeInsets.only(right: 6),
          decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(4)),
        );
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [bar(64, AppColors.primary), bar(40, AppColors.series2), bar(22, AppColors.line)],
    );
  }
}
