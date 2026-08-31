import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smriti/core/constants.dart';

/// Mirrors backend app/models/user.py's UserRole — ASHA/caregiver only. The
/// Patient module never touches this controller at all; it keeps its existing
/// no-login, photo-tile, ASHA-session-context flow per the architecture.
enum AshaCaregiverRole { asha, caregiver }

enum AuthStatus {
  /// Nothing restored from disk yet — show a brief loading state, not the sign-in
  /// screen, or a returning user sees a flash of "sign in" before their session loads.
  unknown,
  signedOut,

  /// Signed in, but this account hasn't completed the one-time role-selection
  /// step yet (see backend POST /api/auth/role) — show that step next.
  awaitingRole,
  signedIn,
}

class AuthState {
  final AuthStatus status;
  final String? token;
  final String? email;
  final AshaCaregiverRole? role;

  const AuthState({required this.status, this.token, this.email, this.role});

  static const initial = AuthState(status: AuthStatus.unknown);
}

/// Passwordless ASHA/caregiver session — find-or-create by email against the
/// backend (see backend app/api/routes/auth.py), JWT persisted to disk so the
/// session survives an app restart until sign-out.
class AuthController extends ValueNotifier<AuthState> {
  AuthController._() : super(AuthState.initial);

  static final AuthController instance = AuthController._();

  /// Real network calls go through this; tests swap it for `http.MockClient`
  /// (see test/auth_controller_test.dart) so login/setRole are exercised
  /// without a live backend, the same way the backend's own tests avoid
  /// needing a real Postgres.
  @visibleForTesting
  http.Client httpClient = http.Client();

  static const _tokenKey = 'auth_token_v1';
  static const _emailKey = 'auth_email_v1';
  static const _roleKey = 'auth_role_v1';

  /// Call once at app startup, before anything reads [value] for real.
  Future<void> restore() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    if (token == null) {
      value = const AuthState(status: AuthStatus.signedOut);
      return;
    }
    final email = prefs.getString(_emailKey);
    final roleName = prefs.getString(_roleKey);
    value = AuthState(
      status: roleName == null ? AuthStatus.awaitingRole : AuthStatus.signedIn,
      token: token,
      email: email,
      role: roleName == null ? null : AshaCaregiverRole.values.byName(roleName),
    );
  }

  /// Returns null on success, or a user-facing error message on failure.
  Future<String?> login(String email) async {
    final http.Response response;
    try {
      response = await httpClient.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );
    } catch (_) {
      return "Couldn't reach the server. Check your connection and try again.";
    }
    if (response.statusCode != 200) {
      return 'That email address is not valid. Please check it and try again.';
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    await _persist(token: body['access_token'] as String, email: email, roleName: body['role'] as String?);
    return null;
  }

  /// Returns null on success, or a user-facing error message on failure.
  Future<String?> setRole(AshaCaregiverRole role) async {
    final token = value.token;
    if (token == null) return 'You were signed out — please sign in again.';

    final http.Response response;
    try {
      response = await httpClient.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/role'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
        body: jsonEncode({'role': role.name}),
      );
    } catch (_) {
      return "Couldn't reach the server. Check your connection and try again.";
    }
    if (response.statusCode != 200) {
      return "Couldn't save that — please try again.";
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    await _persist(token: body['access_token'] as String, email: value.email, roleName: body['role'] as String?);
    return null;
  }

  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([prefs.remove(_tokenKey), prefs.remove(_emailKey), prefs.remove(_roleKey)]);
    value = const AuthState(status: AuthStatus.signedOut);
  }

  Future<void> _persist({required String token, String? email, required String? roleName}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    if (email != null) await prefs.setString(_emailKey, email);
    if (roleName != null) {
      await prefs.setString(_roleKey, roleName);
    } else {
      await prefs.remove(_roleKey);
    }
    value = AuthState(
      status: roleName == null ? AuthStatus.awaitingRole : AuthStatus.signedIn,
      token: token,
      email: email ?? value.email,
      role: roleName == null ? null : AshaCaregiverRole.values.byName(roleName),
    );
  }

  /// Drops in-memory state so a test can start from a clean singleton — this
  /// controller is an app-lifetime singleton like AshaRepository/CaregiverRepository
  /// (see their own resetForTest()), so tests must reset it or inherit a previous
  /// test's signed-in state.
  @visibleForTesting
  void resetForTest() {
    value = AuthState.initial;
    httpClient = http.Client();
  }
}
