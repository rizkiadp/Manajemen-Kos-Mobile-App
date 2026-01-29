import '../network/api_client.dart';

class MaintenanceService {
  final ApiClient _apiClient = ApiClient();

  // Create new maintenance report
  Future<Map<String, dynamic>> createReport({
    required String title,
    required String description,
    required String category,
    String priority = 'medium',
    String? imageUrl,
  }) async {
    try {
      final response = await _apiClient.dio.post('/maintenance-reports', data: {
        'title': title,
        'description': description,
        'category': category,
        'priority': priority,
        if (imageUrl != null) 'image_url': imageUrl,
      });
      return response.data;
    } catch (e) {
      throw Exception('Failed to create report: $e');
    }
  }

  // Get all reports (filtered for tenant, all for admin)
  Future<List<dynamic>> getReports({
    String? status,
    String? category,
    String? priority,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (status != null) queryParams['status'] = status;
      if (category != null) queryParams['category'] = category;
      if (priority != null) queryParams['priority'] = priority;

      final response = await _apiClient.dio.get(
        '/maintenance-reports',
        queryParameters: queryParams,
      );
      return response.data['data'] as List;
    } catch (e) {
      throw Exception('Failed to fetch reports: $e');
    }
  }

  // Get report details
  Future<Map<String, dynamic>> getReportById(int id) async {
    try {
      final response = await _apiClient.dio.get('/maintenance-reports/$id');
      return response.data['data'];
    } catch (e) {
      throw Exception('Failed to fetch report: $e');
    }
  }

  // Update report status (admin only)
  Future<Map<String, dynamic>> updateReportStatus(int id, String status) async {
    try {
      final response = await _apiClient.dio.put('/maintenance-reports/$id', data: {
        'status': status,
      });
      return response.data['data'];
    } catch (e) {
      throw Exception('Failed to update report: $e');
    }
  }

  // Delete report (admin only)
  Future<void> deleteReport(int id) async {
    try {
      await _apiClient.dio.delete('/maintenance-reports/$id');
    } catch (e) {
      throw Exception('Failed to delete report: $e');
    }
  }

  // Get pending reports count (for admin notification)
  Future<int> getPendingCount() async {
    try {
      final response = await _apiClient.dio.get('/maintenance-reports/pending-count');
      return response.data['count'] as int;
    } catch (e) {
      throw Exception('Failed to fetch pending count: $e');
    }
  }
}
