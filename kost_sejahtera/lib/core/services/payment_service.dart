import 'package:dio/dio.dart';
import '../network/api_client.dart';
import 'package:url_launcher/url_launcher.dart';

class PaymentService {
  final ApiClient _client = ApiClient();

  // Create payment transaction
  Future<Map<String, dynamic>> createTransaction({
    required int invoiceId,
    required String paymentMethod,
  }) async {
    try {
      final response = await _client.dio.post(
        '/payments/create-transaction',
        data: {
          'invoice_id': invoiceId,
          'payment_method': paymentMethod,
        },
      );

      if (response.data['success']) {
        return response.data['data'];
      } else {
        throw Exception(response.data['message']);
      }
    } on DioException catch (e) {
      throw _client.handleError(e);
    }
  }

  // Check payment status
  Future<Map<String, dynamic>> checkStatus(String orderId) async {
    try {
      final response = await _client.dio.get('/payments/status/$orderId');

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
