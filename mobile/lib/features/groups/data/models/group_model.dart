import '../../domain/entities/group_entity.dart';

class GroupMemberModel extends GroupMemberEntity {
  const GroupMemberModel({
    required super.id,
    required super.userId,
    required super.userName,
    required super.role,
    required super.joinedAt,
  });

  factory GroupMemberModel.fromJson(Map<String, dynamic> json) {
    return GroupMemberModel(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      userName: json['user_name'] ?? json['name'] ?? 'Anggota',
      role: json['role'] ?? 'member',
      joinedAt: DateTime.tryParse(json['joined_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

class GroupModel extends GroupEntity {
  const GroupModel({
    required super.id,
    required super.name,
    super.description,
    required super.userRole,
    required super.membersCount,
    required super.createdAt,
  });

  factory GroupModel.fromJson(Map<String, dynamic> json) {
    return GroupModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      userRole: json['user_role'] ?? 'member',
      membersCount: json['members_count'] ?? 1,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}
