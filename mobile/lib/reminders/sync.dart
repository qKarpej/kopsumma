import '../state/app_scope.dart';

/// Pēc importa vai pieteikšanās atjauno ieplānotos atgādinājumus (ja lietotājs tos ieslēdzis).
Future<int> syncReminders(AppServices services) async {
  try {
    if (!services.reminders.supported || !await services.settings.remindersOn()) return 0;
    final deadlines = await services.api.deadlines();
    return await services.reminders.schedule(deadlines.upcoming);
  } catch (_) {
    return 0; // atgādinājumi nedrīkst traucēt galveno plūsmu
  }
}
