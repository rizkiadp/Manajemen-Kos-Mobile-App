import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  late Dio _dio;
  
  // Singleton instance
  factory ApiClient() => _instance;

  ApiClient._internal() {
    _dio = Dio(BaseOptions(
      // baseUrl: 'http://localhost:3000/api', // Localhost
      baseUrl: 'https://manajemen-kos-mobile-app.vercel.app/api', // Vercel Production
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Add auth token if exists
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('auth_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) {
        // Handle global errors here if needed
        print('API Error: ${e.message}');
        return handler.next(e);
      },
    ));
  }

  Dio get dio => _dio;

  // Helper method to handle Dio errors
  String handleError(DioException e) {
    if (e.response != null) {
      final message = e.response?.data['message'];
      return message ?? 'Terjadi kesalahan pada server';
    } else if (e.type == DioExceptionType.connectionTimeout) {
      return 'Koneksi timeout. Silakan coba lagi.';
    } else if (e.type == DioExceptionType.receiveTimeout) {
      return 'Server tidak merespon.';
    } else if (e.type == DioExceptionType.connectionError) {
      return 'Tidak dapat terhubung ke server. Pastikan server nyala.';
    } else {
      return 'Terjadi kesalahan: ${e.message}';
    }
  }
}
