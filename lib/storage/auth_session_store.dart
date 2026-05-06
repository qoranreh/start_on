import 'package:shared_preferences/shared_preferences.dart';

class AuthSession {
  const AuthSession({
    required this.email,
    required this.displayName,
  });

  final String email;
  final String displayName;
}

class AuthSessionStore {
  const AuthSessionStore();

  static const _isSignedInKey = 'auth.is_signed_in';
  static const _emailKey = 'auth.email';
  static const _displayNameKey = 'auth.display_name';

  Future<AuthSession?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final isSignedIn = prefs.getBool(_isSignedInKey) ?? false;
    if (!isSignedIn) {
      return null;
    }

    final email = prefs.getString(_emailKey) ?? '';
    final displayName = prefs.getString(_displayNameKey) ?? '';
    if (email.isEmpty || displayName.isEmpty) {
      await clear();
      return null;
    }

    return AuthSession(email: email, displayName: displayName);
  }

  Future<void> save(AuthSession session) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isSignedInKey, true);
    await prefs.setString(_emailKey, session.email);
    await prefs.setString(_displayNameKey, session.displayName);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_isSignedInKey);
    await prefs.remove(_emailKey);
    await prefs.remove(_displayNameKey);
  }
}
