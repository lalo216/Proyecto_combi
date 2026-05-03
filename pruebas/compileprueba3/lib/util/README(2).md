# android_templates

Plantillas de referencia para **CombisChiautempan** (Flutter + Android).
Fuente de verdad cuando `AndroidManifest.xml` o `build.gradle.kts` se rompan
(p. ej. después de que un agente regenere los archivos y pierda permisos).

## Contenido

| Plantilla | Destino en el proyecto | Cuándo usar |
|---|---|---|
| `AndroidManifest.release.xml` | `android/app/src/main/AndroidManifest.xml` | Base de producción; incluye `INTERNET` y `ACCESS_NETWORK_STATE`. |
| `AndroidManifest.debug.xml`   | `android/app/src/debug/AndroidManifest.xml` | Overlay dev; añade `usesCleartextTraffic`. |
| `build.gradle.release.kts`    | `android/app/build.gradle.kts` | Distribución; contiene placeholder para firmar con keystore real. |
| `build.gradle.debug.kts`      | `android/app/build.gradle.kts` | Desarrollo / Waydroid; firma con debug para que `flutter run --release` funcione sin keystore. |

## Reglas críticas (no negociables)

1. `namespace` en `build.gradle.kts` **debe** coincidir con la ruta de `MainActivity.kt`:
   `android/app/src/main/kotlin/mx/combis/combischiautempanrun/MainActivity.kt`
2. `applicationId` = `namespace` = `"mx.combis.combischiautempanrun"`.
3. `android:label` = `"CombisChiautempan"` (NUNCA `combischiautempanrun`).
4. El main manifest **debe** tener `<uses-permission android:name="android.permission.INTERNET"/>` —
   sin esto la app queda 100% offline y rompe sync.php, login, tiles OSM, favorites.
5. En release **nunca** incluir `android:usesCleartextTraffic="true"` — todo el tráfico va por HTTPS (Tailscale).

## Aplicar una plantilla

```bash
# Ejemplo: restaurar manifest de release
cp /home/archymechy/Public/android_templates/AndroidManifest.release.xml \
   /home/archymechy/Public/ClaudeProjectsPC/combischiautempanrun/pruebas/NoSeSiLaLlamariaUnaPrueba/prueba_ya_bonita/android/app/src/main/AndroidManifest.xml
```

Después siempre: `flutter clean && flutter pub get && flutter build apk --release`.
