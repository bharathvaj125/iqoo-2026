class ApiConfig {
  ApiConfig._();

  /// Android emulator loopback to a locally running backend; override per environment.
  static const String baseUrl = 'http://10.0.2.2:8000/api';
}
