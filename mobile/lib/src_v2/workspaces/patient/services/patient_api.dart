import 'package:dio/dio.dart';
import 'package:mobile/src_v2/core/api/api_client.dart';
import 'package:mobile/src_v2/core/auth/patient_token_store.dart';

class PatientApi {
  static Dio get _dio => ApiClient.dio;

  static Future<Options> _opts() async {
    final token = await PatientTokenStore.getAccessToken();
    return Options(
      headers: {if (token != null) 'Authorization': 'Bearer $token'},
    );
  }

  static Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    return _dio.get<T>(
      path,
      queryParameters: queryParameters,
      options: await _opts(),
    );
  }

  static Future<Response<T>> post<T>(String path, {dynamic data}) async {
    return _dio.post<T>(path, data: data, options: await _opts());
  }

  static Future<Response<T>> patch<T>(String path, {dynamic data}) async {
    return _dio.patch<T>(path, data: data, options: await _opts());
  }

  static Future<Response<T>> put<T>(String path, {dynamic data}) async {
    return _dio.put<T>(path, data: data, options: await _opts());
  }

  static Future<Response<T>> delete<T>(String path, {dynamic data}) async {
    return _dio.delete<T>(path, data: data, options: await _opts());
  }
}
