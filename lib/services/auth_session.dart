/// Mirrors the backend's role enum (utils/enum.js).
class UserRole {
  static const String admin = 'admin';
  static const String user = 'user';
  static const String parent = 'parent';
  static const String driver = 'driver';
}

class AuthUser {
  final int id;
  final String firstName;
  final String lastName;
  final String phone;
  final String role;

  const AuthUser({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.role,
  });

  String get name =>
      lastName.isEmpty ? firstName : '$firstName $lastName';
}

/// In-memory session holding the tokens returned by the backend.
///
/// The refresh token is issued as an httpOnly cookie, which the `http`
/// package does not persist on mobile, so its raw cookie value is kept
/// here and sent back manually on /refresh and /logout.
class AuthSession {
  AuthSession._();
  static final AuthSession instance = AuthSession._();

  String? accessToken;
  String? refreshTokenCookie;
  AuthUser? user;

  bool get isLoggedIn => accessToken != null;

  void clear() {
    accessToken = null;
    refreshTokenCookie = null;
    user = null;
  }
}
