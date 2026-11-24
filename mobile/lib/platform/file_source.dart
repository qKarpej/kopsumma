import 'package:file_selector/file_selector.dart';

class PickedFile {
  const PickedFile(this.name, this.bytes);

  final String name;
  final List<int> bytes;
}

/// Izraksta faila izvēle (telefonā — failu pārvaldnieks, pārlūkā — datora fails).
abstract class FileSource {
  Future<PickedFile?> pickStatement();
}

class SystemFileSource implements FileSource {
  const SystemFileSource();

  @override
  Future<PickedFile?> pickStatement() async {
    const csv = XTypeGroup(
      label: 'CSV izraksts',
      extensions: ['csv', 'txt'],
      mimeTypes: ['text/csv', 'text/comma-separated-values', 'text/plain', 'application/vnd.ms-excel'],
      uniformTypeIdentifiers: ['public.comma-separated-values-text', 'public.plain-text'],
    );
    final file = await openFile(acceptedTypeGroups: const [csv]);
    if (file == null) return null;
    return PickedFile(file.name, await file.readAsBytes());
  }
}
