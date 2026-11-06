/// Pure Domain Entity representing an Authenticated User in SakuKu
class UserEntity {
  final String id;
  final String name;
  final String email;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserEntity({
    required this.id,
    required this.name,
    required this.email,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserEntity &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          email == other.email &&
          isActive == other.isActive;

  @override
  int get hashCode =>
      id.hashCode ^ name.hashCode ^ email.hashCode ^ isActive.hashCode;

  @override
  String toString() =>
      'UserEntity(id: $id, name: $name, email: $email, isActive: $isActive)';
}
