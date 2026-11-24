import 'package:flutter/material.dart';

import 'api/api_client.dart';
import 'api/kopsumma_api.dart';
import 'app.dart';
import 'config.dart';
import 'reminders/reminder_service.dart';
import 'state/app_scope.dart';
import 'state/session_store.dart';
import 'state/settings.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settings = PrefsSettingsStore();
  final api = HttpKopsummaApi(ApiClient(baseUrl: apiBaseUrl), store: SecureSessionStore());
  final saved = await settings.serverUrl();
  if (saved != null && saved.isNotEmpty) api.serverUrl = saved;
  runApp(KopsummaApp(
    services: AppServices(api: api, settings: settings, reminders: LocalReminderService()),
  ));
}
