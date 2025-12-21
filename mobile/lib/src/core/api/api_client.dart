import 'package:dio/dio.dart';

import '../config/app_config.dart';
import '../auth/token_store.dart';

class ApiClient {
  ApiClient._();

  static final Dio dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
      sendTimeout: const Duration(seconds: 20),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  static bool _inited = false;

  // ✅ in-memory cache (fast)
  static String? _accessTokenCache;

  // ✅ keep reference to tokenStore for lazy fallback
  static TokenStore? _tokenStore;

  static Future<void> init(TokenStore tokenStore) async {
    if (_inited) return;
    _inited = true;

    _tokenStore = tokenStore;

    // preload once (ok)
    _accessTokenCache = await tokenStore.getAccessToken();

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          var token = _accessTokenCache;

          // ✅ lazy fallback (helps web/edge cases)
          if ((token == null || token.isEmpty) && _tokenStore != null) {
            token = await _tokenStore!.getAccessToken();
            _accessTokenCache = token;
          }

          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          handler.next(options);
        },
        onError: (DioException e, handler) async {
          // no auto-refresh here (keep your current logic)
          handler.next(e);
        },
      ),
    );
  }

  // ✅ call this whenever token changes (login/refresh/logout)
  static void setAccessToken(String? token) {
    _accessTokenCache = token;
  }
}
