/// Runtime configuration sourced from `--dart-define` so the same build
/// can target different `nps-api` deployments without rebuilding.
class AppConfig {
  const AppConfig({
    required this.apiBaseUrl,
    required this.apiKey,
    required this.appId,
  });

  /// Base URL of the nps-api deployment. No trailing slash.
  final String apiBaseUrl;

  /// Value sent in the `X-API-Key` header. Empty string = header omitted
  /// (matches an nps-api deployment that has `API_KEYS` unset).
  final String apiKey;

  /// Value sent as the `app` field on each submission.
  final String appId;

  static const AppConfig fromEnvironment = AppConfig(
    apiBaseUrl: String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'https://api.ruohomaki.fi/nps',
    ),
    apiKey: String.fromEnvironment('API_KEY', defaultValue: ''),
    appId: String.fromEnvironment('APP_ID', defaultValue: 'nps-frontend-demo'),
  );
}
