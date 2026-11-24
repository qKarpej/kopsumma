import 'package:flutter/widgets.dart';

import '../api/kopsumma_api.dart';
import '../platform/file_source.dart';
import '../reminders/reminder_service.dart';
import 'settings.dart';

/// Atkarības visiem ekrāniem bez globāliem mainīgajiem (testos aizstāj ar viltojumiem).
class AppServices {
  AppServices({
    required this.api,
    ReminderService? reminders,
    SettingsStore? settings,
    FileSource? files,
  })  : reminders = reminders ?? const NoopReminderService(),
        settings = settings ?? MemorySettingsStore(),
        files = files ?? const SystemFileSource();

  final KopsummaApi api;
  final ReminderService reminders;
  final SettingsStore settings;
  final FileSource files;
}

class AppScope extends InheritedWidget {
  AppScope({super.key, KopsummaApi? api, AppServices? services, required super.child})
      : assert(api != null || services != null),
        services = services ?? AppServices(api: api!);

  final AppServices services;

  static AppServices of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!.services;

  static KopsummaApi apiOf(BuildContext context) => of(context).api;

  @override
  bool updateShouldNotify(AppScope oldWidget) => services != oldWidget.services;
}
