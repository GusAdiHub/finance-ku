import '../entities/dashboard_data.dart';

abstract class DashboardRepository {
  /// Fetches one-time aggregated dashboard data calculated from local storage
  Future<DashboardData> getDashboardData();

  /// Observes aggregated dashboard data reactively as transactions change
  Stream<DashboardData> watchDashboardData();
}
