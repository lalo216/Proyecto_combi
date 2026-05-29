// El host real NO se escribe en el código fuente (la tailnet FQDN es privada).
// Se inyecta en tiempo de compilación con --dart-define:
//
//   flutter run --dart-define=API_BASE=https://<tailnet-host>/combiapi
//   flutter build apk --dart-define=API_BASE=https://<tailnet-host>/combiapi
// Si alguien olvida el --dart-define, la app cae a un host inválido y los
// requests fallan de forma visible (en vez de filtrar una URL placeholder
// al repo).

class ApiBase {
  static const int serverdbversion = 2;
  static const int localdbversion = 2;
  const ApiBase._();

  static const String apiurl = String.fromEnvironment(
    'API_BASE',
    defaultValue: 'https://api.example.invalid/combiapi',
  );

  static const String clientUa = String.fromEnvironment(
    'CLIENT_UA',
    defaultValue: 'CombiApi-Flutter/xd',
  );

}