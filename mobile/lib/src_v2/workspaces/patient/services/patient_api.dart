import 'package:dio/dio.dart';
import 'package:mobile/src_v2/core/api/api_client.dart';
import 'package:mobile/src_v2/core/auth/patient_token_store.dart';

class PatientApi {
  static Dio get _dio => ApiClient.dio;

  static Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    final token = await PatientTokenStore.getAccessToken();
    return _dio.get<T>(
      path,
      queryParameters: queryParameters,
      options: Options(
        headers: {if (token != null) 'Authorization': 'Bearer $token'},
      ),
    );
  }

  static Future<Response<T>> post<T>(String path, {dynamic data}) async {
    final token = await PatientTokenStore.getAccessToken();
    return _dio.post<T>(
      path,
      data: data,
      options: Options(
        headers: {if (token != null) 'Authorization': 'Bearer $token'},
      ),
    );
  }
}
