class GroupMemberEntity {
  final String id;
  final String userId;
  final String userName;
  final String role; // 'owner' | 'admin' | 'member'
  final DateTime joinedAt;

  const GroupMemberEntity({
    required this.id,
    required this.userId,
    required this.userName,
    required this.role,
    required this.joinedAt,
  });
}

class GroupEntity {
  final String id;
  final String name;
  final String? description;
  final String userRole; // 'owner' | 'admin' | 'member'
  final int membersCount;
  final DateTime createdAt;

  const GroupEntity({
    required this.id,
    required this.name,
    this.description,
    required this.userRole,
    required this.membersCount,
    required this.createdAt,
  });

  bool get isOwner => userRole == 'owner';
  bool get isAdminOrOwner => userRole == 'owner' || userRole == 'admin';
}
