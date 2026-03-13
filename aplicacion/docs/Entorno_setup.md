# Entorno de Desarrollo y Guía de Comandos

## Contexto del Proyecto

El proyecto está organizado como **múltiples subapps Flutter** que eventualmente se unirán en una arquitectura híbrida:

| Subapp | Propósito | Estado |
|--------|-----------|--------|
| `simple_db/` | App principal — UI, navegación, mapa embebido, datos de rutas | Fase 3 activa |
| `routing_service/` | Prototipo de integración con OSRM — polilíneas que siguen calles reales | Experimental |

La idea es que `routing_service/` demuestre cómo consultar OSRM para trazar rutas sobre calles reales, y ese patrón eventualmente se absorbe en la app principal. Por ahora **son proyectos Flutter independientes**, cada uno con su propio `pubspec.yaml`. Si están trabajando en uno, los comandos se corren desde su directorio raíz.

---

## Estructura del Proyecto

*(por definir — se actualizará cuando la estructura de carpetas esté estabilizada)*

---

## Requisitos Previos

- Flutter SDK instalado y en el PATH (`flutter --version` para verificar)
- Android SDK / Android Studio (para builds y emulador)
- VS Code con extensión Flutter + Dart
- Git

**En Windows:** verificar que `flutter` esté en el PATH del sistema. Abrir el proyecto en VS Code, abrir terminal integrada y confirmar que `flutter doctor` no tiene errores críticos.

**En Linux:** mismos pasos. `flutter run -d linux` corre la app de escritorio directamente sin emulador.

---

## Comandos Esenciales y Sus Consecuencias

### `flutter pub get`
Descarga todas las dependencias declaradas en `pubspec.yaml` hacia el cache local. **Siempre correr esto al clonar el repo o al cambiar de rama.**

Si aparece un error como `Because X depends on Y ^1.0.0 which doesn't match...`, hay un conflicto de versiones entre paquetes puede ser que ambas subapps tienen versiones distintas del mismo paquete. Alinear las versiones en ambos `pubspec.yaml` a la misma restricción y correr `flutter pub get` en cada una.
---

### `flutter pub outdated`
Muestra qué dependencias tienen versiones más nuevas disponibles. No cambia nada, solo informa.

```bash
flutter pub outdated
```

La salida tiene columnas: `Current` (lo que tenemos), `Upgradable` (actualizable sin romper semver), `Resolvable` (la última que el resolver puede instalar sin conflictos), `Latest` (la más nueva publicada). Actualizar a `Latest` no siempre es seguro si hay breaking changes.

---

### `flutter pub upgrade`
Actualiza las dependencias a la versión más alta compatible con las restricciones en `pubspec.yaml`. **Cambia `pubspec.lock`** — hacer commit del lock actualizado.

```bash
flutter pub upgrade              # sube hasta donde el semver permite
flutter pub upgrade --major-versions  # ignora restricciones — puede romper la app
```

> !! Después de un upgrade, hacer `flutter clean && flutter pub get` y probar que la app sigue compilando antes de hacer commit.

---

### `flutter clean`
Elimina los artefactos de build (`.dart_tool/`, `build/`, archivos generados). No toca el código ni `pubspec.lock`. Útil cuando hay comportamientos extraños que no se explican por cambios en el código.

```bash
flutter clean
flutter pub get   # siempre seguido de pub get
```

---

### `flutter run`
Compila y lanza la app en el dispositivo/emulador conectado.

```bash
flutter run                        # dispositivo detectado automáticamente
flutter run -d emulator-5554       # emulador específico
flutter run -d web-server --web-port=3578         # servidor web local, especificar el puerto hace mas facil debugear.
flutter run --debug                # modo debug explícito (default)
```

---


**Síntoma 2 — `pubspec.lock` en conflicto con `pubspec.yaml`:**
```
pub get failed (1; Because X >=Y is required by your lockfile but
pubspec.yaml constrains X to <Y)
```
Alguien actualizó `pubspec.yaml` pero el `pubspec.lock` en el repo es de una versión anterior (o viceversa). Solución:
```bash
flutter pub get   # deja que el resolver regenere el lock
```
Si sigue fallando, borrar `pubspec.lock` y regenerar:
```bash
rm pubspec.lock
flutter pub get
```
> Recordar: para apps (no paquetes publicados), `pubspec.lock` **sí va en el repo** para que todos usen las mismas versiones exactas.

**Síntoma 3 — Plugin nativo no encontrado en build:**
```
flutter: Error: Cannot find the plugin 'sqflite'.
```
Paquete en `pubspec.yaml` pero falta `flutter pub get`, o el plugin requiere `minSdkVersion` más alto en Android. Revisar `android/app/build.gradle`.

---

## Compilar APK

### Archivos a revisar ANTES de `flutter build apk`

**1. `pubspec.yaml` — nombre y versión de la app:**
```yaml
name: combisv3          # nombre del paquete (sin espacios, minúsculas)
version: 1.0.0+1        # formato: version_name+version_code
```
El `version_code` (el número después de `+`) es el que Google Play usa para ordenar builds. Incrementarlo en cada build que se distribuya.

**2. `android/app/build.gradle` — configuración Android:**
```gradle
android {
    defaultConfig {
        applicationId "com.equipo.combisapp"   // ID único — cambiar del default
        minSdkVersion 21                        // mínimo Android 5.0
        targetSdkVersion 34
        versionCode 1                           // debe coincidir con pubspec
        versionName "1.0.0"
    }
}
```
> Si `applicationId` sigue siendo `com.example.*`, cambiarlo antes de distribuir.

**3. `android/app/src/main/AndroidManifest.xml` — permisos:**
Si la app usa internet (tiles del mapa, OSRM), verificar que esté presente:
```xml
<uses-permission android:name="android.permission.INTERNET"/>
```

---

### Comandos de build

```bash
# APK debug — más rápido, incluye herramientas de debug, NO para distribución final
flutter build apk --debug

# APK release — optimizado, firmado, listo para distribuir
flutter build apk --release

```

El APK resultante queda en:
```
build/app/outputs/flutter-apk/app-debug.apk
build/app/outputs/flutter-apk/app-release.apk
```

Para instalar directamente en un dispositivo conectado por USB:
Primero configura android studio, abre la carpeta y haz clic en el boton de ajustes en la parte superior derecha:
Haz click en plugins, investiga e installa "dart", "flutter" como si fueran extensiones en visual.
Luego haz click en "languages & frameworks" (o similar menu desplegable que demuestre "Android SDK") En sdk platforms asegurate de tener al menos 'Android 16" instalado y seleccionado, luego en "herramientas sdk" _Requieres_ los siguientes:
Android SDK build-tools
NDK
Cmake
Android Emulator
Android SDK command-line Tools
Android Sdk platform-tools

Los ultimos dos son los mas importantes pues habilitan android studio a descargar la aplicacion directamente al emulador, mediante adb. (_Tip: adb es el controllador universal para dispositivos de android y como desarrolladores lo podemos usar con emulatores para garantizar que nuestras acciones corran, sin GUI_)

Una vez que estas seguro de que tienes todas las dependencias, y se descarguen, puedes regresar a la carpeta del projecto y hacer click en el boton con el telefono y el icono de android, en la barra derecha del programa "Manager de dispositivos", le das clic a la flecha y quieres hacer un dispositivo virtual, no remoto, para que tenga mejor rendimiento. 
Apartir de tener tu emulador listo, puedes prenderlo e intentar comunicarte con aquel mediante flutter: 

```bash
flutter emulators                          # lista emuladores disponibles
flutter emulators --launch <emulator_id>   # lanza un emulador específico
flutter devices   
```

---

## Checklist de Verificación Rápida

Antes de decir "pero, no funciona en mi máquina":

- [ ] `flutter doctor` sin errores críticos
- [ ] `flutter pub get` corrido después del último pull
- [ ] App corre en Android (emulador o dispositivo físico)
- [ ] Navegación entre las 3 pestañas funciona
- [ ] El mapa carga tiles (requiere internet)
- [ ] Los botones de ruta resaltan polilíneas en el mapa
- [ ] No hay errores rojos en la consola al usar la app

---

## Troubleshooting

**`flutter pub get` falla con error de red**
En el laboratorio con internet intermitente, los paquetes de pub.dev pueden no descargarse. Si el `pubspec.lock` ya está en el repo, `flutter pub get` intentará usar el cache local primero. Si hay fallo de red repetido, verificar conectividad y reintentar.

**`sqflite_common_ffi` no compila en Windows**
Esta dependencia tiene binarios nativos que difieren entre plataformas. En Linux de escritorio funciona; en Windows puede necesitar configuración adicional de CMake. La solución limpia es usar solo `sqflite` (sin el sufijo `_ffi`) apuntando a Android como target, que es nuestra plataforma principal. Ver discusión en `ARCHITECTURE.md`.

**Hot reload no refleja cambios**
Si los cambios son en `initState()`, constructores, o datos que se cargan al inicio, usar hot restart (`R`) o reinicio completo (`flutter run`).

**Build APK falla con `minSdkVersion` error**
Alguna dependencia requiere un SDK mínimo más alto que el configurado. Subir `minSdkVersion` en `android/app/build.gradle` al valor que indique el error (normalmente 21 es suficiente para sqflite y flutter_map).