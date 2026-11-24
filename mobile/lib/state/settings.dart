import 'package:shared_preferences/shared_preferences.dart';

/// Lietotāja iestatījumi ierīcē: servera adrese (testēšanai telefonā) un atgādinājumi.
abstract class SettingsStore {
  Future<String?> serverUrl();
  Future<void> setServerUrl(String? url);
  Future<bool> remindersOn();
  Future<void> setRemindersOn(bool on);
}

class PrefsSettingsStore implements SettingsStore {
  static const _server = 'kopsumma.server_url';
  static const _reminders = 'kopsumma.reminders';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  @override
  Future<String?> serverUrl() async => (await _prefs).getString(_server);

  @override
  Future<void> setServerUrl(String? url) async {
    final p = await _prefs;
    url == null ? await p.remove(_server) : await p.setString(_server, url);
  }

  @override
  Future<bool> remindersOn() async => (await _prefs).getBool(_reminders) ?? false;

  @override
  Future<void> setRemindersOn(bool on) async => (await _prefs).setBool(_reminders, on);
}

class MemorySettingsStore implements SettingsStore {
  String? server;
  bool reminders = false;

  @override
  Future<String?> serverUrl() async => server;

  @override
  Future<void> setServerUrl(String? url) async => server = url;

  @override
  Future<bool> remindersOn() async => reminders;

  @override
  Future<void> setRemindersOn(bool on) async => reminders = on;
}
