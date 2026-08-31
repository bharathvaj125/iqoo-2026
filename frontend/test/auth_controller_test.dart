import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smriti/core/auth_controller.dart';

/// Exercises AuthController's actual request/response/persistence logic against a
/// mocked HTTP client — no live backend needed, the same way the backend's own
/// pytest suite avoids needing a real Postgres (see backend/tests/conftest.py).
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AuthController.instance.resetForTest();
  });

  http.Response jsonResponse(Map<String, dynamic> body, {int status = 200}) =>
      http.Response(jsonEncode(body), status, headers: {'content-type': 'application/json'});

  test('login on success moves to awaitingRole for a brand-new (role-less) account', () async {
    AuthController.instance.httpClient = MockClient((request) async {
      expect(request.url.path, endsWith('/auth/login'));
      expect(jsonDecode(request.body), {'email': 'new@example.com'});
      return jsonResponse({'access_token': 'tok-123', 'token_type': 'bearer', 'role': null});
    });

    final error = await AuthController.instance.login('new@example.com');

    expect(error, isNull);
    expect(AuthController.instance.value.status, AuthStatus.awaitingRole);
    expect(AuthController.instance.value.token, 'tok-123');
    expect(AuthController.instance.value.email, 'new@example.com');
  });

  test('login on success moves straight to signedIn for a returning account with a role', () async {
    AuthController.instance.httpClient = MockClient((request) async {
      return jsonResponse({'access_token': 'tok-456', 'token_type': 'bearer', 'role': 'caregiver'});
    });

    await AuthController.instance.login('returning@example.com');

    expect(AuthController.instance.value.status, AuthStatus.signedIn);
    expect(AuthController.instance.value.role, AshaCaregiverRole.caregiver);
  });

  test('login surfaces a user-facing error on a non-200 response, without changing state', () async {
    AuthController.instance.httpClient = MockClient((request) async {
      return http.Response('', 422);
    });

    final error = await AuthController.instance.login('not-an-email');

    expect(error, isNotNull);
    expect(AuthController.instance.value.status, AuthStatus.unknown);
  });

  test('login surfaces a user-facing error when the network call itself throws', () async {
    AuthController.instance.httpClient = MockClient((request) async {
      throw const SocketExceptionStub();
    });

    final error = await AuthController.instance.login('offline@example.com');

    expect(error, contains("Couldn't reach"));
  });

  test('setRole refuses to call the network at all when not signed in', () async {
    var called = false;
    AuthController.instance.httpClient = MockClient((request) async {
      called = true;
      return jsonResponse({'access_token': 'x', 'role': 'asha'});
    });

    final error = await AuthController.instance.setRole(AshaCaregiverRole.asha);

    expect(called, isFalse);
    expect(error, isNotNull);
  });

  test('setRole after login moves the state to signedIn with the chosen role', () async {
    AuthController.instance.httpClient = MockClient((request) async {
      if (request.url.path.endsWith('/auth/login')) {
        return jsonResponse({'access_token': 'tok-789', 'role': null});
      }
      expect(jsonDecode(request.body), {'role': 'asha'});
      return jsonResponse({'access_token': 'tok-789-with-role', 'role': 'asha'});
    });

    await AuthController.instance.login('fresh@example.com');
    expect(AuthController.instance.value.status, AuthStatus.awaitingRole);

    final error = await AuthController.instance.setRole(AshaCaregiverRole.asha);

    expect(error, isNull);
    expect(AuthController.instance.value.status, AuthStatus.signedIn);
    expect(AuthController.instance.value.role, AshaCaregiverRole.asha);
    expect(AuthController.instance.value.token, 'tok-789-with-role');
  });

  test('restore reads a previously persisted session back from disk', () async {
    AuthController.instance.httpClient = MockClient((request) async {
      return jsonResponse({'access_token': 'persisted-tok', 'role': 'caregiver'});
    });
    await AuthController.instance.login('persisted@example.com');
    await AuthController.instance.setRole(AshaCaregiverRole.caregiver);

    // Simulate an app restart: in-memory state gone, but SharedPreferences (the
    // mocked disk) still has what was written.
    AuthController.instance.resetForTest();
    expect(AuthController.instance.value.status, AuthStatus.unknown);

    await AuthController.instance.restore();

    expect(AuthController.instance.value.status, AuthStatus.signedIn);
    expect(AuthController.instance.value.email, 'persisted@example.com');
    expect(AuthController.instance.value.role, AshaCaregiverRole.caregiver);
  });

  test('restore with nothing on disk yields signedOut, not unknown forever', () async {
    await AuthController.instance.restore();
    expect(AuthController.instance.value.status, AuthStatus.signedOut);
  });

  test('signOut clears both the in-memory state and what was persisted', () async {
    AuthController.instance.httpClient = MockClient((request) async {
      return jsonResponse({'access_token': 'tok', 'role': 'asha'});
    });
    await AuthController.instance.login('leaving@example.com');

    await AuthController.instance.signOut();
    expect(AuthController.instance.value.status, AuthStatus.signedOut);

    // Nothing left on disk for a subsequent restore() to pick back up.
    AuthController.instance.resetForTest();
    await AuthController.instance.restore();
    expect(AuthController.instance.value.status, AuthStatus.signedOut);
  });
}

/// A network-layer failure without depending on dart:io's SocketException
/// (unavailable/awkward under flutter test's VM in some configurations) —
/// AuthController only cares that *something* was thrown, not its exact type.
class SocketExceptionStub implements Exception {
  const SocketExceptionStub();
}
