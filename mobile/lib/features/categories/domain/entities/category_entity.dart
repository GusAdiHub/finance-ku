/// Pure Domain Entity representing a Financial Category in SakuKu
class CategoryEntity {
  final String id;
  final String name;
  final String type; // 'income' or 'expense'
  final String? icon;
  final String? color;
  final bool isSystem;
  final String? userId;

  const CategoryEntity({
    required this.id,
    required this.name,
    required this.type,
    this.icon,
    this.color,
    this.isSystem = false,
    this.userId,
  });

  bool get isExpense => type == 'expense';
  bool get isIncome => type == 'income';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CategoryEntity &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          type == other.type &&
          isSystem == other.isSystem;

  @override
  int get hashCode =>
      id.hashCode ^ name.hashCode ^ type.hashCode ^ isSystem.hashCode;

  @override
  String toString() =>
      'CategoryEntity(id: $id, name: $name, type: $type, isSystem: $isSystem)';
}
