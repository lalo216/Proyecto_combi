// config/api_base.dart — Fuente única del URL base del API.
//
// El host real NO se escribe en el código fuente (la tailnet FQDN es privada).
// Se inyecta en tiempo de compilación con --dart-define:
//
//   flutter run --dart-define=API_BASE=https://<tailnet-host>/combiapi
//   flutter build apk --dart-define=API_BASE=https://<tailnet-host>/combiapi
//
// Si alguien olvida el --dart-define, la app cae a un host inválido y los
// requests fallan de forma visible (en vez de filtrar una URL placeholder
// al repo).
class ApiBase {
  const ApiBase._();

  static const String url = String.fromEnvironment(
    'API_BASE',
    defaultValue: 'https://api.example.invalid/combiapi',
  );
}
