import 'package:flutter/widgets.dart';

import '../api/kopsumma_api.dart';

/// Padod API visiem ekrāniem bez globāliem mainīgajiem (testos aizstāj ar viltojumu).
class AppScope extends InheritedWidget {
  const AppScope({super.key, required this.api, required super.child});

  final KopsummaApi api;

  static KopsummaApi apiOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!.api;

  @override
  bool updateShouldNotify(AppScope oldWidget) => api != oldWidget.api;
}
