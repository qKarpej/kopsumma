import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../api/models.dart';
import 'deadline_calendar.dart';

/// Atgādinājumi par nodokļa termiņiem kā telefona paziņojumi.
abstract class ReminderService {
  /// Vai šī platforma atbalsta ieplānotus paziņojumus (pārlūkā — nē).
  bool get supported;

  /// Ieplāno visus nākamos atgādinājumus; atgriež ieplānoto skaitu (0 — nav atļaujas).
  Future<int> schedule(List<Deadline> deadlines);
  Future<void> cancelAll();
  Future<bool> showTest(Deadline? next);
}

class NoopReminderService implements ReminderService {
  const NoopReminderService();

  @override
  bool get supported => false;

  @override
  Future<int> schedule(List<Deadline> deadlines) async => 0;

  @override
  Future<void> cancelAll() async {}

  @override
  Future<bool> showTest(Deadline? next) async => false;
}

class LocalReminderService implements ReminderService {
  LocalReminderService({DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  final DateTime Function() _clock;
  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'nodokla_termini',
      'Nodokļa termiņi',
      channelDescription: 'Atgādinājumi par deklarēšanas un samaksas termiņiem',
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(),
  );

  @override
  bool get supported => !kIsWeb;

  Future<bool> _init() async {
    if (!supported) return false;
    if (!_ready) {
      tzdata.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Europe/Riga'));
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(),
        ),
      );
      _ready = true;
    }
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    final granted = await android?.requestNotificationsPermission();
    final ios = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    final iosGranted = await ios?.requestPermissions(alert: true, badge: true, sound: true);
    return (granted ?? true) && (iosGranted ?? true);
  }

  @override
  Future<int> schedule(List<Deadline> deadlines) async {
    if (!await _init()) return 0;
    await _plugin.cancelAll();
    final now = _clock();
    var id = 0;
    for (final d in deadlines.where((d) => !d.past)) {
      for (final at in reminderTimes(d, now)) {
        await _plugin.zonedSchedule(
          id: ++id,
          title: 'Nodokļa termiņš',
          body: reminderText(d, at),
          scheduledDate: tz.TZDateTime(tz.local, at.year, at.month, at.day, at.hour),
          notificationDetails: _details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      }
    }
    return id;
  }

  @override
  Future<void> cancelAll() async {
    if (_ready) await _plugin.cancelAll();
  }

  @override
  Future<bool> showTest(Deadline? next) async {
    if (!await _init()) return false;
    await _plugin.show(
      id: 999,
      title: 'Nodokļa termiņš',
      body: next == null ? 'Atgādinājumi ir ieslēgti.' : reminderText(next, _clock()),
      notificationDetails: _details,
    );
    return true;
  }
}
