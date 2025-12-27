import 'package:dio/dio.dart';
import '../../../../core/api/api_client.dart';

class DepartmentsApiService {
  const DepartmentsApiService();

  Dio get _dio => ApiClient.dio;

  Future<List<Map<String, dynamic>>> listDepartments() async {
    final res = await _dio.get(
      '/api/departments',
      queryParameters: {'limit': 200, 'offset': 0},
    );
    final data = res.data;
    final items = (data is Map && data['items'] is List)
        ? data['items'] as List
        : <dynamic>[];
    return items.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }
}
