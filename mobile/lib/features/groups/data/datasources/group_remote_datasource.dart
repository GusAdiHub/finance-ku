import 'package:dio/dio.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/group_model.dart';

abstract class GroupRemoteDataSource {
  Future<List<GroupModel>> getGroups();
  Future<GroupModel> createGroup(String name, String? description);
  Future<GroupModel> joinGroup(String code);
  Future<List<GroupMemberModel>> getGroupMembers(String groupId);
  Future<String> createInvitationCode(String groupId);
  Future<void> leaveGroup(String groupId);
}

class GroupRemoteDataSourceImpl implements GroupRemoteDataSource {
  final Dio _dio;

  GroupRemoteDataSourceImpl(this._dio);

  @override
  Future<List<GroupModel>> getGroups() async {
    try {
      final response = await _dio.get(ApiEndpoints.groups);
      if (response.statusCode == 200) {
        final list = response.data as List<dynamic>;
        return list
            .map((e) => GroupModel.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        throw ServerException(
          response.data['detail'] ?? 'Gagal memuat kas tim.',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      final detail = e.response?.data is Map
          ? (e.response?.data['detail'] ?? e.message)
          : e.message;
      throw ServerException(
        detail?.toString() ?? 'Gagal memuat kas tim.',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<GroupModel> createGroup(String name, String? description) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.groups,
        data: {
          'name': name,
          if (description != null && description.isNotEmpty)
            'description': description,
        },
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return GroupModel.fromJson(response.data as Map<String, dynamic>);
      } else {
        throw ServerException(
          response.data['detail'] ?? 'Gagal membuat grup kas tim.',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      final detail = e.response?.data is Map
          ? (e.response?.data['detail'] ?? e.message)
          : e.message;
      throw ServerException(
        detail?.toString() ?? 'Gagal membuat grup kas tim.',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<GroupModel> joinGroup(String code) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.joinGroup,
        data: {'code': code.trim().toUpperCase()},
      );
      if (response.statusCode == 200) {
        return GroupModel.fromJson(response.data as Map<String, dynamic>);
      } else {
        throw ServerException(
          response.data['detail'] ?? 'Kode undangan tidak valid.',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      final detail = e.response?.data is Map
          ? (e.response?.data['detail'] ?? e.message)
          : e.message;
      throw ServerException(
        detail?.toString() ?? 'Gagal bergabung ke kas tim.',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<List<GroupMemberModel>> getGroupMembers(String groupId) async {
    try {
      final response = await _dio.get(ApiEndpoints.groupMembers(groupId));
      if (response.statusCode == 200) {
        final list = response.data as List<dynamic>;
        return list
            .map((e) => GroupMemberModel.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        throw ServerException(
          response.data['detail'] ?? 'Gagal memuat anggota grup.',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      final detail = e.response?.data is Map
          ? (e.response?.data['detail'] ?? e.message)
          : e.message;
      throw ServerException(
        detail?.toString() ?? 'Gagal memuat anggota grup.',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<String> createInvitationCode(String groupId) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.groupInvitations(groupId),
        data: {'expires_in_days': 7, 'max_uses': 5},
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data['code'] ?? '';
      } else {
        throw ServerException(
          response.data['detail'] ?? 'Gagal membuat kode undangan.',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      final detail = e.response?.data is Map
          ? (e.response?.data['detail'] ?? e.message)
          : e.message;
      throw ServerException(
        detail?.toString() ?? 'Gagal membuat kode undangan.',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<void> leaveGroup(String groupId) async {
    try {
      await _dio.post(ApiEndpoints.groupLeave(groupId));
    } on DioException catch (e) {
      final detail = e.response?.data is Map
          ? (e.response?.data['detail'] ?? e.message)
          : e.message;
      throw ServerException(
        detail?.toString() ?? 'Gagal keluar dari grup.',
        statusCode: e.response?.statusCode,
      );
    }
  }
}
