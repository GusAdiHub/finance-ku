import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/dashboard_repository_impl.dart';
import '../../domain/entities/dashboard_data.dart';
import '../../domain/repositories/dashboard_repository.dart';

class DashboardState {
  final DashboardData data;
  final bool isLoading;
  final String? errorMessage;

  const DashboardState({
    required this.data,
    this.isLoading = false,
    this.errorMessage,
  });

  DashboardState copyWith({
    DashboardData? data,
    bool? isLoading,
    String? errorMessage,
  }) {
    return DashboardState(
      data: data ?? this.data,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

final dashboardControllerProvider =
    NotifierProvider<DashboardController, DashboardState>(
  DashboardController.new,
);

class DashboardController extends Notifier<DashboardState> {
  late final DashboardRepository _repository;
  StreamSubscription<DashboardData>? _subscription;

  @override
  DashboardState build() {
    _repository = ref.watch(dashboardRepositoryProvider);
    _init();
    ref.onDispose(() {
      _subscription?.cancel();
    });
    return DashboardState(data: DashboardData.empty(), isLoading: true);
  }

  void _init() {
    _subscription = _repository.watchDashboardData().listen(
      (data) {
        state = DashboardState(data: data, isLoading: false);
      },
      onError: (err) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: err.toString(),
        );
      },
    );
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true);
    try {
      final fresh = await _repository.getDashboardData();
      state = DashboardState(data: fresh, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }
}
