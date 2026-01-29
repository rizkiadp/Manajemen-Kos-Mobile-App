import 'package:dio/dio.dart';
import '../network/api_client.dart';

class TenantService {
  final ApiClient _client = ApiClient();

  // Get all tenants
  Future<List<Map<String, dynamic>>> getTenants({String? search, String? status}) async {
    try {
      final response = await _client.dio.get(
        '/tenants',
        queryParameters: {
          if (search != null && search.isNotEmpty) 'search': search,
          if (status != null && status != 'Semua') 'status': status,
        },
      );

      if (response.data['success']) {
        return List<Map<String, dynamic>>.from(response.data['data']);
      } else {
        throw Exception(response.data['message']);
      }
    } on DioException catch (e) {
      throw _client.handleError(e);
    }
  }

  // Get active tenants
  Future<List<Map<String, dynamic>>> getActiveTenants() async {
    try {
      final response = await _client.dio.get(
        '/tenants',
        queryParameters: {'status': 'active'},
      );

      if (response.data['success']) {
        return List<Map<String, dynamic>>.from(response.data['data']);
      } else {
        throw Exception(response.data['message']);
      }
    } on DioException catch (e) {
      throw _client.handleError(e);
    }
  }

  // Get tenant by ID
  Future<Map<String, dynamic>> getTenantById(int id) async {
    try {
      final response = await _client.dio.get('/tenants/$id');

      if (response.data['success']) {
        return response.data['data'];
      } else {
        throw Exception(response.data['message']);
      }
    } on DioException catch (e) {
      throw _client.handleError(e);
    }
  }

  // Create tenant
  Future<void> createTenant(Map<String, dynamic> data) async {
    try {
      final response = await _client.dio.post('/tenants', data: data);

      if (!response.data['success']) {
        throw Exception(response.data['message']);
      }
    } on DioException catch (e) {
      throw _client.handleError(e);
    }
  }

  // Update tenant
  Future<void> updateTenant(int id, Map<String, dynamic> data) async {
    try {
      final response = await _client.dio.put('/tenants/$id', data: data);

      if (!response.data['success']) {
        throw Exception(response.data['message']);
      }
    } on DioException catch (e) {
      throw _client.handleError(e);
    }
  }

  // Delete tenant
  Future<void> deleteTenant(int id) async {
    try {
      final response = await _client.dio.delete('/tenants/$id');

      if (!response.data['success']) {
        throw Exception(response.data['message']);
      }
    } on DioException catch (e) {
      throw _client.handleError(e);
    }
  }
}
