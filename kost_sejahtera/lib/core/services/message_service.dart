import 'package:dio/dio.dart';
import '../network/api_client.dart';

class MessageService {
  final ApiClient _apiClient = ApiClient();

  // Send message
  Future<Map<String, dynamic>> sendMessage({
    required int reportId,
    required String message,
    int? receiverId,
  }) async {
    try {
      final response = await _apiClient.dio.post('/messages', data: {
        'report_id': reportId,
        'message': message,
        if (receiverId != null) 'receiver_id': receiverId,
      });
      return response.data['data'];
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  // Get conversation for a report
  Future<List<dynamic>> getConversation(int reportId) async {
    try {
      final response = await _apiClient.dio.get('/messages/conversation/$reportId');
      return response.data['data'] as List;
    } catch (e) {
      throw Exception('Failed to fetch conversation: $e');
    }
  }

  // Get unread message count
  Future<int> getUnreadCount() async {
    try {
      final response = await _apiClient.dio.get('/messages/unread-count');
      return response.data['count'] as int;
    } catch (e) {
      throw Exception('Failed to fetch unread count: $e');
    }
  }

  // Mark message as read
  Future<void> markAsRead(int messageId) async {
    try {
      await _apiClient.dio.put('/messages/$messageId/read');
    } catch (e) {
      throw Exception('Failed to mark as read: $e');
    }
  }
}
