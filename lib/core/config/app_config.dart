class AppConfig {
  /// La API desplegada es la opción por defecto. Para pruebas simuladas,
  /// compila con --dart-define=USE_MOCK_API=true.
  static const bool useMock = bool.fromEnvironment(
    'USE_MOCK_API',
    defaultValue: false,
  );

  /// Sobrescribe con --dart-define=API_URL=... para desarrollo o pruebas.
  static const String baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'https://minimarket-api.duckdns.org',
  );
}
