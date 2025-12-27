import 'package:dio/dio.dart';
import '../../../../core/api/api_client.dart';

class RoomsApiService {
  const RoomsApiService();

  Dio get _dio => ApiClient.dio;

  Future<List<Map<String, dynamic>>> listRooms({
    required String departmentId,
  }) async {
    final res = await _dio.get(
      '/api/rooms',
      queryParameters: {
        'departmentId': departmentId,
        'limit': 200,
        'offset': 0,
      },
    );
    final data = res.data;
    final items = (data is Map && data['items'] is List)
        ? data['items'] as List
        : <dynamic>[];
    return items.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }
}
