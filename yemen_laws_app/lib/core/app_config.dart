class AppConfig {
  AppConfig._();

  static const legalAiBaseUrl = String.fromEnvironment(
    'LEGAL_AI_BASE_URL',
    defaultValue: '',
  );

  static const appVersion = String.fromEnvironment(
    'APP_VERSION',
    defaultValue: '1.0.0',
  );
}
