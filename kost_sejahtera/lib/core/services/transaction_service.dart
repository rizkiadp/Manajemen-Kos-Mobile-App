import 'package:dio/dio.dart';
import '../network/api_client.dart';

class TransactionService {
  final ApiClient _client = ApiClient();

  // Get transactions with filter
  Future<List<Map<String, dynamic>>> getTransactions({
    String? type,
    String? category,
    String? startDate,
    String? endDate,
  }) async {
    try {
      final response = await _client.dio.get(
        '/transactions',
        queryParameters: {
          if (type != null) 'type': type,
          if (category != null) 'category': category,
          if (startDate != null) 'startDate': startDate,
          if (endDate != null) 'endDate': endDate,
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

  // Get transaction summary
  Future<Map<String, dynamic>> getTransactionSummary() async {
    try {
      final response = await _client.dio.get('/transactions/summary');

      if (response.data['success']) {
        return response.data['data'];
      } else {
        throw Exception(response.data['message']);
      }
    } on DioException catch (e) {
      throw _client.handleError(e);
    }
  }

  // Create invoice
  Future<void> createInvoice(Map<String, dynamic> data) async {
    try {
      final response = await _client.dio.post('/invoices', data: data);

      if (!response.data['success']) {
        throw Exception(response.data['message']);
      }
    } on DioException catch (e) {
      throw _client.handleError(e);
    }
  }

  // Get invoices
  Future<List<Map<String, dynamic>>> getInvoices({String? status}) async {
    try {
      final response = await _client.dio.get(
        '/invoices',
        queryParameters: {
          if (status != null) 'status': status,
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
}
