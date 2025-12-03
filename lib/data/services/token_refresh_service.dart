import 'package:diary_garden/core/storage/token_storage.dart';
import 'package:diary_garden/data/datasource/auth_api_client.dart';
import 'package:flutter/foundation.dart';

/// 토큰 자동 갱신을 관리하는 서비스
class TokenRefreshService {
  TokenRefreshService({AuthApiClient? authApiClient})
      : _authApiClient = authApiClient ?? AuthApiClient();

  final AuthApiClient _authApiClient;
  bool _isRefreshing = false;

  /// 토큰 갱신 콜백 (로그아웃 처리 등을 위해)
  VoidCallback? onTokenExpired;

  /// AccessToken이 만료되었을 때 RefreshToken으로 갱신 시도
  Future<String?> refreshIfNeeded() async {
    // 이미 갱신 중이면 대기
    if (_isRefreshing) {
      debugPrint('TokenRefreshService: Already refreshing, waiting...');
      await Future.delayed(const Duration(milliseconds: 500));
      return TokenStorage.readToken();
    }

    _isRefreshing = true;

    try {
      final refreshToken = await TokenStorage.readRefreshToken();
      
      if (refreshToken == null || refreshToken.isEmpty) {
        debugPrint('TokenRefreshService: No refresh token available');
        onTokenExpired?.call();
        return null;
      }

      debugPrint('TokenRefreshService: Attempting to refresh access token...');
      final session = await _authApiClient.refreshAccessToken(refreshToken);

      if (!session.hasToken) {
        debugPrint('TokenRefreshService: Failed to get new access token');
        onTokenExpired?.call();
        return null;
      }

      // 새 토큰 저장
      await TokenStorage.saveTokens(
        accessToken: session.token,
        refreshToken: session.refreshToken ?? refreshToken,
      );

      debugPrint('TokenRefreshService: Access token refreshed successfully');
      return session.token;
    } catch (e) {
      debugPrint('TokenRefreshService: Failed to refresh token: $e');
      onTokenExpired?.call();
      return null;
    } finally {
      _isRefreshing = false;
    }
  }

  /// 토큰 검증 (verify 엔드포인트 사용)
  Future<bool> verifyToken(String token) async {
    try {
      await _authApiClient.verifyToken(token);
      return true;
    } catch (e) {
      debugPrint('TokenRefreshService: Token verification failed: $e');
      return false;
    }
  }
}
