import 'package:dio/dio.dart';
import '../../core/api/api_client.dart';

class TasksApiService {
  TasksApiService();

  Dio get _dio => ApiClient.dio;

  Future<Map<String, dynamic>> listMyTasks({
    String? status,
    int limit = 30,
    int offset = 0,
  }) async {
    final res = await _dio.get(
      '/api/tasks/my',
      queryParameters: {
        if (status != null && status.isNotEmpty) 'status': status,
        'limit': limit,
        'offset': offset,
      },
    );

    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<Map<String, dynamic>> startTask(String taskId) async {
    final res = await _dio.post('/api/tasks/$taskId/start');
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<Map<String, dynamic>> completeTask(
    String taskId, {
    String? note,
  }) async {
    final res = await _dio.post(
      '/api/tasks/$taskId/complete',
      data: {'note': note},
    );
    return Map<String, dynamic>.from(res.data as Map);
  }
}
