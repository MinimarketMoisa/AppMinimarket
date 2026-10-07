class AppConfig {
  /// true  = la app usa datos simulados (no necesita API).
  /// false = la app se conecta a la API real en [baseUrl].
  static const bool useMock = true;

  /// 10.0.2.2 = localhost desde el emulador Android.
  /// En celular físico usa la IP de tu PC, ej: http://192.168.1.50:8000
  /// También: flutter run --dart-define=API_URL=https://mi-api.com
  static const String baseUrl =
      String.fromEnvironment('API_URL', defaultValue: 'http://10.0.2.2:8000');
}