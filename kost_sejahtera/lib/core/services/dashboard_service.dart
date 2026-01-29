import 'package:dio/dio.dart';
import '../network/api_client.dart';

class DashboardService {
  final ApiClient _client = ApiClient();

  // Get admin dashboard stats
  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final response = await _client.dio.get('/dashboard/admin');

      if (response.data['success']) {
        return response.data['data'];
      } else {
        throw Exception(response.data['message']);
      }
    } on DioException catch (e) {
      throw _client.handleError(e);
    }
  }

  // Get financial trend data
  Future<Map<String, dynamic>> getFinancialTrend() async {
    try {
      final response = await _client.dio.get('/dashboard/financial-trend');

      if (response.data['success']) {
        return response.data['data'];
      } else {
        throw Exception(response.data['message']);
      }
    } on DioException catch (e) {
      throw _client.handleError(e);
    }
  }
}
