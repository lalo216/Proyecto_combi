# combis app — Arquitectura y Guía del Desarrollador

Este documento explica lo que hace cada archivo, de qué es responsable cada parte del sistema, y como podriamos seguir.

---

## Contexto del Proyecto

Combis App es una guía de tránsito móvil para rutas de combis en Tlaxcala. La meta es mostrar rutas en un mapa real, permitir explorar paradas, y eventualmente mostrar posiciones en tiempo real. Plataforma objetivo: **Android**. Desarrollo activo en **Linux desktop** (con emulador) y **Windows** (VS Code + extensiones C++).

---

## Arquitectura General — Fase 3b

```
Flutter App (combisv3)
        │
        │  HTTPS — Tailscale / MagicDNS
        ▼
mechyserver.taile37db1.ts.net/combiapi/
        │
        ▼ Caddy (Docker, rootless) → reverse_proxy → Apache2:3200
                │                        │
                │                        └── /var/www/html/combiapi/
                │                              ├── check.php
                │                              ├── v1/rutas.php
                │                              └── v1/sync.php (futuro)
                │
        ┌───────┴──────────┐
        ▼                  ▼
   SQLite                MySQL 8.0
(combis_cache.db)       (combis_db)
 - rutas                - usuarios (V2+)
 - paradas              - credenciales
 - meta_sync            - favoritos (V2+)
 Datos públicos         Datos sensibles
 Cacheable / offline    Nunca al cliente
```

### Regla fundamental de sincronización

La app **nunca escribe** datos de rutas/paradas directamente. Solo lee del cache local. El servidor **empuja** datos nuevos mediante `sync.php`. La app solo acepta un sync si:

1. La `schema_version` del servidor difiere de la versión local en `meta_sync`.
2. No hay actividad de usuario activa en ese momento.

Esto previene conflictos de escritura entre versiones de la app y actualizaciones del equipo.

---

## Flujo de Arranque

```
App inicia
    │
    ├─ BootPage
    │     ├─ checkHealth() → check.php    [paralelo]
    │     └─ estaInicializada() → SQLite  [paralelo]
    │           └─ si no → SeedData.sembrar()
    │
    └─ "Continuar" habilitado cuando SQLite está lista
          │
          └─ MainScreen (3 pestañas)
```

El servidor puede estar caído — la app arranca de todas formas con datos locales. La BD local **sí** debe estar sembrada para continuar.

---

## La historia hasta ahora

### Fase 1 — Prototipo Original
Canvas map personalizado con `CustomPainter`, SQLite conectado, pestaña Dev. Datos sembrados en `main.dart`. Código existe en el repo pero no está en nav.

### Fase 2 — Reconstrucción Limpia
SQLite deshabilitado. Tiles reales con `flutter_map`. Paleta "Vibrant Sunset". Todo hardcodeado en páginas. 
pruebas_mapa ayudo durante este tiempo

### Fase 3 — Mapa en Página Principal
Mapa en `HomePage` como tarjeta. `MapWidget` reutilizable con overlays de polilíneas y marcadores. Datos hardcodeados en `route_data.dart`. Pestaña Perfil placeholder.
Resultado de ln

### Fase 3b — Final versiones de las bd

**Lo que podriamos tener:**
- SQLite re-habilitado 
- `BootPage` nueva: verifica servidor + siembra BD antes de dejar pasar al usuario
- `DbHelper` (singleton) maneja el esquema local con 3 tablas: `rutas`, `paradas`, `meta_sync`
- `SeedData` contiene datos de inicio con IDs permanentes (no renumerar sin migración)
- `route_data.dart` ya no tiene datos hardcodeados — contiene `cargarOverlaysDesBD()` que convierte modelos de BD a `RouteOverlay` para `MapWidget`
- `ApiService` maneja `checkHealth()` y `fetchRutas()` con el envelope JSON estándar
- `HomePage` carga rutas desde BD local en lugar de lista estática
- `main.dart` inicializa SQLite FFI en desktop y apunta home a `BootPage`

- `sync.php` endpoint + lógica de sync en la app
- Autenticación de usuarios (MySQL)
- Preferencias y rutas favoritas
- Perfil page completa

---

## Desglose Archivo por Archivo

Nota, lo siguiente no ha sido actualizado:

### `lib/main.dart`
Corre `CombisApp` apuntando a `BootPage`, mantiene la nav bar en memoria.

### `lib/pages/boot_page.dart`
Pantalla de arranque con estética industrial (SourceCodePro, near-black, indicadores de estado). Corre `checkHealth()` y verifica/siembra la BD en paralelo. El botón "Continuar" solo se habilita cuando la BD local está lista. Servidor offline no bloquea el arranque.

### `lib/pages/main_screen.dart`
Shell raíz con `BottomNavigationBar` (3 tabs) e `IndexedStack`. Sin cambios respecto a Fase 3.

### `lib/pages/home_page.dart`
Llama `cargarOverlaysDesBD()` en `initState` para obtener rutas de SQLite. El mapa y la cuadrícula reflejan datos reales. Botón de refresh recarga desde BD.

### `lib/pages/routes_page.dart`, `profile_page.dart`
Sin cambios respecto a Fase 3. `RoutesPage` aún usa datos estáticos hasta Fase 4.

### `lib/database/db_helper.dart`
Singleton SQLite. Tablas: `rutas`, `paradas`, `meta_sync`. Métodos clave:
- `estaInicializada()` — ¿ya hay rutas en la BD?
- `sembrar(rutas, paradas)` — limpia e inserta en transacción
- `obtenerRutas()` — solo activas por defecto
- `obtenerParadasDeRuta(rutaId)` — ordenadas por `orden ASC`
- `leerMeta / escribirMeta` — para `schema_version` y otros flags de sync

Errores de init expuestos en `errorNotifier` para que la UI reaccione.

### `lib/models/modelos.dart`
`Ruta` — id, nombre, numero, colorHex, activo. Método `color` convierte hex a `Color`.  
`Parada` — id, rutaId, nombre, latitud, longitud, orden.  
Ambos tienen `fromMap / toMap` para SQLite.

### `lib/data/seed_data.dart`
Datos de inicio con IDs permanentes (1–3 para rutas, 101–303 para paradas). Método estático `sembrar()`. Los IDs deben ser constantes — el favorito de un usuario apunta al ID de la ruta, no a su nombre.

### `lib/data/route_data.dart`
Ya no contiene datos hardcodeados. Contiene `RouteOverlay`, `StopPoint`, y `cargarOverlaysDesBD()` que construye overlays para el mapa desde la BD local.

### `lib/services/api_service.dart`
Singleton HTTP. `checkHealth()` → `check.php`. `fetchRutas()` → `v1/rutas.php`. Todos los métodos devuelven `ApiResponse` con `ok`, `data`, `message`, y `schemaVersion`. Timeout de 8s. Nunca lanza excepciones — atrapa y devuelve `ApiResponse.error(...)`.

### `lib/widgets/map_widget.dart`
Sin cambios. Acepta `List<RouteOverlay>` — ahora viene de BD en lugar de hardcodeado.

### `lib/theme/`
Sin cambios respecto a Fase 3.

### `lib/utils/common.dart`
Sin cambios. `debugLog` / `errorLog` solo en `kDebugMode`.

---

## Esquema SQLite Local

```sql
-- Rutas de transporte público (datos públicos, cacheables)
CREATE TABLE rutas (
  id        INTEGER PRIMARY KEY,   -- constante, nunca renumerar
  nombre    TEXT    NOT NULL,
  numero    TEXT    NOT NULL,
  color_hex TEXT    NOT NULL DEFAULT '#FF6D00',
  activo    INTEGER NOT NULL DEFAULT 1  -- 0 = en mantenimiento
);

-- Paradas ordenadas por ruta
CREATE TABLE paradas (
  id        INTEGER PRIMARY KEY,
  ruta_id   INTEGER NOT NULL REFERENCES rutas(id) ON DELETE CASCADE,
  nombre    TEXT    NOT NULL,
  latitud   REAL    NOT NULL,
  longitud  REAL    NOT NULL,
  orden     INTEGER NOT NULL       -- 0 = inicio de ruta
);

-- Metadatos de sincronización
CREATE TABLE meta_sync (
  clave TEXT PRIMARY KEY,
  valor TEXT NOT NULL
  -- schema_version: versión del servidor con el que sincronizamos
  -- last_sync: timestamp del último sync exitoso
);
```

---

## Envelope JSON del Servidor

Todos los endpoints responden con esta estructura:

```json
{
  "status": "ok",
  "data": { "..." },
  "meta": {
    "timestamp": "2026-03-24T12:00:00+00:00",
    "version": "1.0",
    "schema_version": "1"
  },
  "message": null
}
```

`status` es el primer campo que lee la app. `message` se muestra solo en errores. `schema_version` en `meta` se compara con `meta_sync.valor` de la BD local para disparar sync.

---

## Reglas de Equipo

- **No renumerar IDs de rutas** sin una migración que actualice las FKs en MySQL y notifique a la app.
- Si una ruta está en desarrollo, poner `activo = 0` en lugar de eliminarla.
- No agregar endpoints que salten `check.php` / `bootstrap.php` del servidor.
- Pull al inicio de cada sesión. Push frecuente. Commits descriptivos en español.
- Cambios al esquema de BD: incrementar `dbVersion` en `DbHelper` e implementar `onUpgrade`.

---

## Lo que encontraras en la prueba /pruebas/pruebas_bases/intentopegar

| Elemento | Estado |
|----------|--------|
| `sync.php` endpoint | Pendiente Fase 4 |
| Auth / MySQL desde la app | Pendiente Fase 4 |
| `ProfilePage` completa | Pendiente Fase 4 |
| `RoutesPage` desde BD | Pendiente Fase 4 |
| `DevPage` como hamburguesa | Pendiente Fase 4 |
| Favoritos | Pendiente Fase 4 |
