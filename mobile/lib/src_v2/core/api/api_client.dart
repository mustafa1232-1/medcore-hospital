// ignore_for_file: avoid_print

import 'package:dio/dio.dart';

import '../config/app_config.dart';
import '../auth/token_store.dart';
import '../auth/auth_service.dart';

class ApiClient {
  ApiClient._();

  static final Dio dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
      sendTimeout: const Duration(seconds: 20),
      headers: const {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },

      // ✅ نبقيها < 500 حتى تقدر تقرأ body في 4xx بسهولة
      // لكن هذا يعني 401 لن يرمي error تلقائياً -> نعالجه في onResponse
      validateStatus: (code) => code != null && code < 500,
    ),
  );

  static bool _inited = false;

  // in-memory cache
  static String? _accessTokenCache;

  // token store reference
  static TokenStore? _tokenStore;

  // refresh lock
  static Future<void>? _refreshing;

  static Future<void> init(TokenStore tokenStore) async {
    if (_inited) return;
    _inited = true;

    _tokenStore = tokenStore;
    _accessTokenCache = await tokenStore.getAccessToken();

    // ✅ 1) Logging interceptor
    dio.interceptors.add(
      LogInterceptor(
        request: true,
        requestHeader: true,
        requestBody: true,
        responseHeader: false,
        responseBody: true,
        error: true,
        logPrint: (o) => print(o),
      ),
    );

    // ✅ 2) Auth + refresh/retry interceptor
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          var token = _accessTokenCache;

          if ((token == null || token.isEmpty) && _tokenStore != null) {
            token = await _tokenStore!.getAccessToken();
            _accessTokenCache = token;
          }

          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          } else {
            options.headers.remove('Authorization');
          }

          handler.next(options);
        },

        // ✅ IMPORTANT:
        // لأن validateStatus يسمح 401، Dio لن يدخل onError.
        // لذلك نحول 401 في response إلى error لكي يشتغل refresh/retry.
        onResponse: (response, handler) async {
          final status = response.statusCode;

          if (status == 401) {
            final path = response.requestOptions.path;
            final isAuthCall =
                path.contains('/api/auth/login') ||
                path.contains('/api/auth/refresh') ||
                path.contains('/api/auth/logout');

            if (!isAuthCall) {
              final ex = DioException(
                requestOptions: response.requestOptions,
                response: response,
                type: DioExceptionType.badResponse,
                message: 'Unauthorized',
              );
              handler.reject(ex);
              return;
            }
          }

          handler.next(response);
        },

        onError: (DioException e, handler) async {
          // ✅ اطبع تفاصيل مفيدة
          print('❌ DIO ERROR: ${e.type} ${e.message}');
          print('❌ URL: ${e.requestOptions.method} ${e.requestOptions.uri}');
          if (e.response != null) {
            print('❌ STATUS: ${e.response?.statusCode}');
            print('❌ DATA: ${e.response?.data}');
          }

          // only handle 401
          final status = e.response?.statusCode;
          if (status != 401) {
            handler.next(e);
            return;
          }

          // do not refresh for auth endpoints themselves
          final path = e.requestOptions.path;
          final isAuthCall =
              path.contains('/api/auth/login') ||
              path.contains('/api/auth/refresh') ||
              path.contains('/api/auth/logout');

          if (isAuthCall) {
            handler.next(e);
            return;
          }

          // avoid infinite retry loop
          final alreadyRetried = e.requestOptions.extra['__retried'] == true;
          if (alreadyRetried) {
            handler.next(e);
            return;
          }

          try {
            await _refreshOnce();

            final req = e.requestOptions;
            req.extra['__retried'] = true;

            // clone headers safely
            final clonedHeaders = Map<String, dynamic>.from(req.headers);

            // attach fresh token if available
            final token = _accessTokenCache;
            if (token != null && token.isNotEmpty) {
              clonedHeaders['Authorization'] = 'Bearer $token';
            } else {
              clonedHeaders.remove('Authorization');
            }

            final retryRes = await dio.request(
              req.path,
              data: req.data,
              queryParameters: req.queryParameters,
              options: Options(
                method: req.method,
                headers: clonedHeaders,
                responseType: req.responseType,
                contentType: req.contentType,
                followRedirects: req.followRedirects,
                validateStatus: req.validateStatus,
                receiveDataWhenStatusError: req.receiveDataWhenStatusError,
                sendTimeout: req.sendTimeout,
                receiveTimeout: req.receiveTimeout,
              ),
            );

            handler.resolve(retryRes);
          } catch (_) {
            // refresh failed => clear tokens then pass original error
            try {
              await _tokenStore?.clear();
            } catch (_) {}
            setAccessToken(null);
            handler.next(e);
          }
        },
      ),
    );
  }

  // call this whenever token changes (login/refresh/logout)
  static void setAccessToken(String? token) {
    _accessTokenCache = token;
  }

  static Future<void> _refreshOnce() async {
    // if already refreshing, await same future
    if (_refreshing != null) return _refreshing!;

    _refreshing = () async {
      final store = _tokenStore;
      if (store == null) throw Exception('TokenStore not initialized');

      final refreshToken = await store.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        throw Exception('No refresh token');
      }

      final res = await AuthService.refresh(refreshToken: refreshToken);

      final newAccess = (res['accessToken'] ?? '').toString();
      final newRefresh = (res['refreshToken'] ?? '').toString();

      if (newAccess.isEmpty || newRefresh.isEmpty) {
        throw Exception('Invalid refresh response');
      }

      await store.saveTokens(accessToken: newAccess, refreshToken: newRefresh);
      setAccessToken(newAccess);
    }();

    try {
      await _refreshing;
    } finally {
      _refreshing = null;
    }
  }
}
