import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../data/datasources/group_remote_datasource.dart';
import '../../data/models/group_model.dart';
import '../../domain/entities/group_entity.dart';

final groupRemoteDataSourceProvider = Provider<GroupRemoteDataSource>((ref) {
  final dio = ref.watch(dioProvider);
  return GroupRemoteDataSourceImpl(dio);
});

class GroupsState {
  final List<GroupEntity> groups;
  final bool isLoading;
  final String? errorMessage;
  final String? createdInviteCode;

  const GroupsState({
    required this.groups,
    this.isLoading = false,
    this.errorMessage,
    this.createdInviteCode,
  });

  GroupsState copyWith({
    List<GroupEntity>? groups,
    bool? isLoading,
    String? errorMessage,
    String? createdInviteCode,
    bool clearError = false,
  }) {
    return GroupsState(
      groups: groups ?? this.groups,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      createdInviteCode: createdInviteCode ?? this.createdInviteCode,
    );
  }
}

final groupsControllerProvider =
    NotifierProvider<GroupsController, GroupsState>(GroupsController.new);

class GroupsController extends Notifier<GroupsState> {
  late final GroupRemoteDataSource _remoteDataSource;

  @override
  GroupsState build() {
    _remoteDataSource = ref.watch(groupRemoteDataSourceProvider);
    _loadGroups();
    return const GroupsState(groups: [], isLoading: true);
  }

  Future<void> _loadGroups() async {
    try {
      final list = await _remoteDataSource.getGroups();
      state = state.copyWith(groups: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, clearError: true);
    await _loadGroups();
  }

  Future<GroupModel?> createGroup(String name, String? description) async {
    try {
      final newGroup = await _remoteDataSource.createGroup(name, description);
      await _loadGroups();
      return newGroup;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return null;
    }
  }

  Future<GroupModel?> joinGroup(String code) async {
    try {
      final joined = await _remoteDataSource.joinGroup(code);
      await _loadGroups();
      return joined;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return null;
    }
  }

  Future<String?> generateInviteCode(String groupId) async {
    try {
      final code = await _remoteDataSource.createInvitationCode(groupId);
      state = state.copyWith(createdInviteCode: code);
      return code;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return null;
    }
  }
}
