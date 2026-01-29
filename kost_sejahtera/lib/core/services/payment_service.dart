import 'package:dio/dio.dart';

class PaymentService {
  final Dio _dio = Dio();
  
  // TODO: Replace with your backend URL
  final String _baseUrl = 'https://your-backend-url.com/api';
  
  // TODO: Replace with your Midtrans keys
  final String _serverKey = 'YOUR_MIDTRANS_SERVER_KEY';
  final String _clientKey = 'YOUR_MIDTRANS_CLIENT_KEY';

  PaymentService() {
    _dio.options.baseUrl = _baseUrl;
    _dio.options.headers = {
      'Content-Type': 'application/json',
    };
  }

  /// Create Midtrans transaction
  /// Returns transaction token for payment
  Future<Map<String, dynamic>> createTransaction({
    required String invoiceId,
    required double amount,
    required Map<String, dynamic> customerDetails,
    required String paymentMethod,
  }) async {
    try {
      final response = await _dio.post(
        '/payments/create-transaction',
        data: {
          'order_id': invoiceId,
          'gross_amount': amount,
          'customer_details': customerDetails,
          'payment_method': paymentMethod,
        },
      );

      return response.data;
    } catch (e) {
      throw Exception('Failed to create transaction: $e');
    }
  }

  /// Check payment status
  Future<Map<String, dynamic>> checkPaymentStatus(String orderId) async {
    try {
      final response = await _dio.get('/payments/status/$orderId');
      return response.data;
    } catch (e) {
      throw Exception('Failed to check payment status: $e');
    }
  }

  /// Cancel transaction
  Future<void> cancelTransaction(String orderId) async {
    try {
      await _dio.post('/payments/cancel/$orderId');
    } catch (e) {
      throw Exception('Failed to cancel transaction: $e');
    }
  }

  /// Get payment methods
  Future<List<Map<String, dynamic>>> getPaymentMethods() async {
    // This is a mock implementation
    // In production, fetch from backend
    return [
      {
        'type': 'bank_transfer',
        'providers': ['BCA', 'Mandiri', 'BNI', 'BRI'],
      },
      {
        'type': 'ewallet',
        'providers': ['GoPay', 'OVO', 'ShopeePay', 'DANA'],
      },
      {
        'type': 'qris',
        'providers': ['QRIS'],
      },
    ];
  }
}
