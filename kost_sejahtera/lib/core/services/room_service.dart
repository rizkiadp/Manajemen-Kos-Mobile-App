import 'package:dio/dio.dart';
import '../network/api_client.dart';

class RoomService {
  final ApiClient _client = ApiClient();

  // Get all rooms
  Future<List<Map<String, dynamic>>> getRooms({String? search, String? filter}) async {
    try {
      final response = await _client.dio.get(
        '/rooms',
        queryParameters: {
          if (search != null && search.isNotEmpty) 'search': search,
          if (filter != null && filter != 'Semua') 'type': filter,
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

  // Get available rooms
  Future<List<Map<String, dynamic>>> getAvailableRooms() async {
    try {
      final response = await _client.dio.get(
        '/rooms',
        queryParameters: {'available': 'true'},
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

  // Get room by ID
  Future<Map<String, dynamic>> getRoomById(int id) async {
    try {
      final response = await _client.dio.get('/rooms/$id');

      if (response.data['success']) {
        return response.data['data'];
      } else {
        throw Exception(response.data['message']);
      }
    } on DioException catch (e) {
      throw _client.handleError(e);
    }
  }

  // Create room
  Future<void> createRoom(Map<String, dynamic> data) async {
    try {
      final response = await _client.dio.post('/rooms', data: data);

      if (!response.data['success']) {
        throw Exception(response.data['message']);
      }
    } on DioException catch (e) {
      throw _client.handleError(e);
    }
  }

  // Update room
  Future<void> updateRoom(int id, Map<String, dynamic> data) async {
    try {
      final response = await _client.dio.put('/rooms/$id', data: data);

      if (!response.data['success']) {
        throw Exception(response.data['message']);
      }
    } on DioException catch (e) {
      throw _client.handleError(e);
    }
  }

  // Delete room
  Future<void> deleteRoom(int id) async {
    try {
      final response = await _client.dio.delete('/rooms/$id');

      if (!response.data['success']) {
        throw Exception(response.data['message']);
      }
    } on DioException catch (e) {
      throw _client.handleError(e);
    }
  }
}
