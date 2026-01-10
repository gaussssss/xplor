import '../../domain/entities/file_entry.dart';

class GroupSection {
  const GroupSection({
    required this.label,
    required this.entries,
  });

  final String label;
  final List<FileEntry> entries;
}
