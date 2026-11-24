import 'package:kopsumma/api/models.dart';
import 'package:kopsumma/platform/file_source.dart';
import 'package:kopsumma/reminders/reminder_service.dart';

class FakeFiles implements FileSource {
  FakeFiles([this.next]);

  PickedFile? next;

  @override
  Future<PickedFile?> pickStatement() async => next;
}

class FakeReminders implements ReminderService {
  final scheduled = <Deadline>[];
  bool cancelled = false;

  @override
  bool get supported => true;

  @override
  Future<int> schedule(List<Deadline> deadlines) async {
    scheduled
      ..clear()
      ..addAll(deadlines);
    return deadlines.length * 3;
  }

  @override
  Future<void> cancelAll() async => cancelled = true;

  @override
  Future<bool> showTest(Deadline? next) async => true;
}
