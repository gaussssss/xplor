enum FileColumn {
  name,
  size,
  dateModified,
  kind,
  dateCreated,
  dateAccessed,
  permissions,
  tags,
}

enum SortOrder { ascending, descending }

class SortConfig {
  const SortConfig({
    required this.column,
    required this.order,
  });

  final FileColumn column;
  final SortOrder order;

  SortConfig toggle() {
    return SortConfig(
      column: column,
      order: order == SortOrder.ascending
          ? SortOrder.descending
          : SortOrder.ascending,
    );
  }
}
