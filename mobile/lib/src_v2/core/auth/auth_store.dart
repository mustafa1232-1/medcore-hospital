import 'package:flutter/material.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

import 'token_store.dart';
import 'auth_service.dart';
import '../api/api_client.dart';

class AuthStore extends ChangeNotifier {
  final TokenStore _tokenStore = TokenStore();

  bool _isReady = false;
  bool _isAuthenticated = false;

  Map<String, dynamic>? _user;

  bool get isReady => _isReady;
  bool get isAuthenticated => _isAuthenticated;
  Map<String, dynamic>? get user => _user;

  Future<void> bootstrap() async {
    await ApiClient.init(_tokenStore);

    final accessToken = await _tokenStore.getAccessToken();
    final refreshToken = await _tokenStore.getRefreshToken();

    if (accessToken == null || refreshToken == null) {
      ApiClient.setAccessToken(null);
      _finishUnauth();
      return;
    }

    // ✅ ensure ApiClient uses stored access token
    ApiClient.setAccessToken(accessToken);

    if (JwtDecoder.isExpired(accessToken)) {
      try {
        final res = await AuthService.refresh(refreshToken: refreshToken);

        final newAccess = (res['accessToken'] ?? '').toString();
        final newRefresh = (res['refreshToken'] ?? '').toString();

        if (newAccess.isEmpty || newRefresh.isEmpty) {
          throw Exception('Invalid refresh response');
        }

        await _tokenStore.saveTokens(
          accessToken: newAccess,
          refreshToken: newRefresh,
        );

        ApiClient.setAccessToken(newAccess);
      } catch (_) {
        await _tokenStore.clear();
        ApiClient.setAccessToken(null);
        _finishUnauth();
        return;
      }
    }

    try {
      final me = await AuthService.me();
      _user = me['user'];
      _finishAuth();
    } catch (_) {
      await _tokenStore.clear();
      ApiClient.setAccessToken(null);
      _finishUnauth();
    }
  }

  /// Login action (tenant code OR uuid)
  Future<void> login({
    required String tenant,
    String? email,
    String? phone,
    required String password,
  }) async {
    final res = await AuthService.login(
      tenant: tenant,
      email: email,
      phone: phone,
      password: password,
    );

    final access = (res['accessToken'] ?? '').toString();
    final refresh = (res['refreshToken'] ?? '').toString();

    if (access.isEmpty || refresh.isEmpty) {
      throw Exception('Invalid login response');
    }

    await _tokenStore.saveTokens(accessToken: access, refreshToken: refresh);

    // ✅ critical: update ApiClient cache immediately
    ApiClient.setAccessToken(access);

    // Prefer fetching /me for canonical user payload
    try {
      final me = await AuthService.me();
      _user = me['user'];
    } catch (_) {
      _user = res['user'];
    }

    _finishAuth();
  }

  Future<void> logout() async {
    final refreshToken = await _tokenStore.getRefreshToken();
    if (refreshToken != null) {
      try {
        await AuthService.logout(refreshToken: refreshToken);
      } catch (_) {}
    }

    await _tokenStore.clear();
    ApiClient.setAccessToken(null);
    _finishUnauth();
  }

  void _finishAuth() {
    _isAuthenticated = true;
    _isReady = true;
    notifyListeners();
  }

  void _finishUnauth() {
    _isAuthenticated = false;
    _user = null;
    _isReady = true;
    notifyListeners();
  }
}
