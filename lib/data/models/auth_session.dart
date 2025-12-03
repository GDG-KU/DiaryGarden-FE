class AuthSession {
  const AuthSession({
    required this.token,
    required this.uid,
    required this.email,
    required this.displayName,
    required this.username,
    this.refreshToken,
  });

  final String token;
  final String uid;
  final String email;
  final String displayName;
  final String username;
  final String? refreshToken;

  factory AuthSession.fromJson(Map<String, dynamic> json, {String? fallbackToken}) {
    return AuthSession(
      token: (json['token'] ?? fallbackToken ?? '').toString(),
      uid: (json['uid'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      displayName: (json['displayName'] ?? json['nickname'] ?? '').toString(),
      username: (json['username'] ?? '').toString(),
      refreshToken: json['refreshToken']?.toString(),
    );
  }

  bool get hasToken => token.isNotEmpty;
  bool get hasRefreshToken => refreshToken != null && refreshToken!.isNotEmpty;
}
