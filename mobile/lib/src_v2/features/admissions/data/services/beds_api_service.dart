import 'package:dio/dio.dart';
import '../../../../core/api/api_client.dart';

class BedsApiService {
  const BedsApiService();

  Dio get _dio => ApiClient.dio;

  Future<List<Map<String, dynamic>>> listBeds({required String roomId}) async {
    final res = await _dio.get(
      '/api/beds',
      queryParameters: {'roomId': roomId, 'limit': 500, 'offset': 0},
    );
    final data = res.data;
    final items = (data is Map && data['items'] is List)
        ? data['items'] as List
        : <dynamic>[];
    return items.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }
}
