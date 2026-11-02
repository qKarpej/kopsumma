import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../theme/app_theme.dart';

/// Četri ekrāna stāvokļi vienā vietā: loading, empty, error, ready.
class AsyncView<T> extends StatefulWidget {
  const AsyncView({
    super.key,
    required this.load,
    required this.isEmpty,
    required this.ready,
    required this.empty,
    this.loading,
  });

  final Future<T> Function() load;
  final bool Function(T data) isEmpty;
  final Widget Function(BuildContext context, T data, Future<void> Function() reload) ready;
  final Widget Function(BuildContext context) empty;
  final Widget Function(BuildContext context)? loading;

  @override
  State<AsyncView<T>> createState() => _AsyncViewState<T>();
}

class _AsyncViewState<T> extends State<AsyncView<T>> {
  late Future<T> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.load();
  }

  Future<void> _reload() async {
    final next = widget.load();
    setState(() {
      _future = next;
    });
    try {
      await next;
    } catch (_) {
      // kļūdu parāda FutureBuilder
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return widget.loading?.call(context) ??
              const Center(child: CircularProgressIndicator(key: Key('state-loading')));
        }
        if (snap.hasError) {
          final err = snap.error;
          final message = err is ApiException ? err.message : 'Radās neparedzēta kļūda.';
          return ErrorState(key: const Key('state-error'), message: message, onRetry: _reload);
        }
        final data = snap.data as T;
        if (widget.isEmpty(data)) {
          return KeyedSubtree(key: const Key('state-empty'), child: widget.empty(context));
        }
        return KeyedSubtree(key: const Key('state-ready'), child: widget.ready(context, data, _reload));
      },
    );
  }
}

class ErrorState extends StatelessWidget {
  const ErrorState({super.key, required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(color: AppColors.dangerBg, shape: BoxShape.circle),
              child: const Icon(Icons.wifi_off_rounded, color: AppColors.danger, size: 36),
            ),
            const SizedBox(height: 16),
            Text('Datus neizdevās ielādēt', style: text.titleMedium, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(message, style: text.bodyMedium, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            FilledButton(onPressed: onRetry, child: const Text('Mēģināt vēlreiz')),
          ],
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.title, required this.message});

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppColors.muted),
            const SizedBox(height: 16),
            Text(title, style: text.titleMedium, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(message, style: text.bodyMedium, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
