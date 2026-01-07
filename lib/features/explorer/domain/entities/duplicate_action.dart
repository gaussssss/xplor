enum DuplicateActionType {
  replace,
  duplicate,
  skip,
}

class DuplicateAction {
  const DuplicateAction({
    required this.type,
    this.newName,
  });

  final DuplicateActionType type;
  final String? newName;

  DuplicateAction copyWith({
    DuplicateActionType? type,
    String? newName,
  }) {
    return DuplicateAction(
      type: type ?? this.type,
      newName: newName ?? this.newName,
    );
  }
}
