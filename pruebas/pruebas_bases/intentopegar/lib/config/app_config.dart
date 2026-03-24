/// Configuración centralizada de la app.
///
/// Cambiar [apiBaseUrl] para apuntar al servidor correcto.
/// En desarrollo usa la IP de Tailscale; en producción usa el dominio.
class AppConfig {
  AppConfig._();

  /// Versión de la app (mostrada en UI y app bar).
  static const String appVersion = '0.1.0';

  /// Nombre visible de la app.
  static const String appName = 'Combis Tlaxcala';

  /// URL base de la API REST.
  /// Cambiar a la IP/dominio de tu servidor Tailscale.
  /// Ejemplo: 'http://mechyserver.taile.ts.net/combiapi'
  /// Ejemplo local: 'http://100.x.x.x/combiapi'
  static const String apiBaseUrl = 'http://localhost:3200/myapp/combiapi';

  /// Timeout para requests HTTP (en segundos).
  static const int httpTimeoutSeconds = 10;

  /// Nombre de la base de datos SQLite local.
  static const String localDbName = 'combis_cache.db';

  /// Versión del schema SQLite local.
  /// Incrementar manualmente si se cambia el schema.
  static const int localDbVersion = 1;
}
