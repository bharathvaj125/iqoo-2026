import 'package:flutter/foundation.dart';

class ApiConfig {
  ApiConfig._();

  /// The Android emulator's loopback to the host machine is 10.0.2.2, not
  /// localhost — everywhere else (web, iOS simulator, desktop) the backend
  /// really is at 127.0.0.1. Override per real deployment environment.
  static String get baseUrl {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000/api';
    }
    return 'http://127.0.0.1:8000/api';
  }
}
