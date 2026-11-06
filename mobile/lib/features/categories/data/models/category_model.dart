import '../../domain/entities/category_entity.dart';

/// Data Transfer Object for Category
class CategoryModel {
  final String id;
  final String name;
  final String type; // 'income' or 'expense'
  final String? icon;
  final String? color;
  final bool isSystem;
  final String? userId;
  final String? groupId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.type,
    this.icon,
    this.color,
    this.isSystem = false,
    this.userId,
    this.groupId,
    this.createdAt,
    this.updatedAt,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      icon: json['icon'] as String?,
      color: json['color'] as String?,
      isSystem: json['is_system'] as bool? ?? false,
      userId: json['user_id'] as String?,
      groupId: json['group_id'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)?.toUtc()
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)?.toUtc()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      if (icon != null) 'icon': icon,
      if (color != null) 'color': color,
      'is_system': isSystem,
      if (userId != null) 'user_id': userId,
      if (groupId != null) 'group_id': groupId,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  CategoryEntity toEntity() {
    return CategoryEntity(
      id: id,
      name: name,
      type: type,
      icon: icon,
      color: color,
      isSystem: isSystem,
      userId: userId,
    );
  }

  factory CategoryModel.fromEntity(CategoryEntity entity) {
    return CategoryModel(
      id: entity.id,
      name: entity.name,
      type: entity.type,
      icon: entity.icon,
      color: entity.color,
      isSystem: entity.isSystem,
      userId: entity.userId,
    );
  }
}
