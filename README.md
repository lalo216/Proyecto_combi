# Combis App — Guía de Tránsito para Chiautempan, Tlaxcala


> Una guía de transporte público moderna para las rutas de combis en un estado peque de México. Desarrollada con Flutter.

App móvil (Android) que muestra rutas de combis en un mapa OpenStreetMap. El usuario selecciona dónde está, ve qué combis pasan cerca y consulta el recorrido completo de cada ruta.

**Plataforma objetivo:** Android (APK sideload).  
**Desarrollo:** Linux desktop + Windows (VS Code mas paquete de extensiones c++), emulador Waydroid o dispositivo físico. Flutter SDK y git. 
**Stack servidor:** PHP 8.3 + MySQL 8.0 sobre Caddy, accesible vía Tailscale.
---

## Arquitectura general

```
┌──────────────────────┐        HTTPS / Tailscale        ┌──────────────────────────────┐
│  Flutter App          │  ◄──────────────────────────►   │  mechyserver                  │
│  SQLite (cache local) │                                 │  Caddy → PHP-FPM → MySQL      │
│  offline-first        │                                 │  /var/www/html/myapp/combiapi/ │
└──────────────────────┘                                  └──────────────────────────────┘
```

La app sigue el patrón **C$SS (Client-Cache-Stateless-Server)**: SQLite en el dispositivo es un cache de solo lectura para rutas y paradas; MySQL en el servidor es la fuente de verdad. La app nunca escribe datos de rutas directamente — los recibe del servidor mediante `sync.php`. Datos sensibles (usuarios, auth, favoritos) vivirán exclusivamente en MySQL.

La app **debe funcionar sin internet**. Un seed de datos hardcodeado (`seed_data.dart`) se incluye en el binario para que las rutas se muestren incluso en la primera ejecución sin conectividad.

---

## Estado del proyecto

Actualmente llevamos un buen avance:

### Servidor y API — Finalizados ✅

Todos los endpoints están desplegados, probados y respondiendo correctamente desde `mechyserver`.

### Base de datos MySQL — Finalizada ✅

Esquema creado, datos sembrados (3 rutas, 9 paradas), usuario de API con permisos mínimos.

### Modelos y capa de datos Flutter...

`Ruta`, `Parada`, `DatabaseHelper`, `SeedData` — Son hasta ahora, los únicos modelos que tenemos.

Además, `ApiService`, `BootPage`, `RouteRepository` — la capa que conecta la app con el servidor están listas para desarrollo.

### 📋 Pendiente

UI principal (mapa, selector de ubicación, detalle de rutas), auth, favoritos, geolocalización, un mejor nombre y posiblemente un dominio.

---

## Servidor y API

### Acceso

| Campo | Valor |
|-------|-------|
| Base URL | `Se las dare no se preocupen` |
| Archivos en servidor | `/var/www/html/.../.../` |
| Mirror en repo | `server/` |
| Acceso de red | Solo Tailscale (Lane A, Caddy → PHP-FPM) |
| Base de datos | `combis_db` en MySQL 8.0 local |

### Endpoints

| Endpoint | Método | Estado | Descripción |
|----------|--------|--------|-------------|
| `check.php` | GET | ✅ Live | Health check. Retorna `ok` o `degraded` según estado de MySQL |
| `routes.php` | GET | ✅ Live | Todas las rutas activas con paradas embebidas. Soporta `?id=N` |
| `sync.php` | GET | ✅ Live | Acepta `?client_version=N`. Retorna payload completo si el cliente está desactualizado, o `up_to_date` si coincide |
| `common.php` | — | ✅ Live | Bootstrap interno (no es endpoint público). Define `sendJson()`, `getMysqlConnection()`, `SCHEMA_VERSION` |

### Envelope JSON

Todos los endpoints responden con esta estructura:

```json
{
  "status": "ok",
  "data": { ... },
  "meta": {
    "timestamp": "2026-04-14T12:00:00+00:00",
    "version": "1.0",
    "schema_version": "1"
  },
  "message": null
}
```

La app lee `status` primero para decidir su flujo. `message` solo aparece en errores. `schema_version` en `meta` se compara con `meta_sync.valor` en SQLite local para decidir si sincronizar.

### Ejemplo: `routes.php`

```
GET /combiapi/routes.php
```

Respuesta (simplificada):

```json
{
  "status": "ok",
  "data": [
    {
      "id": 1,
      "number": "A",
      "name": "Centro → Volcanes",
      "color": "#FF6D00",
      "description": "Ruta principal del centro a la zona de Volcanes",
      "start_point": "Zócalo de Chiautempan",
      "end_point": "Volcanes",
      "estimated_time": 25,
      "is_active": 1,
      "stops": [
        { "id": 1, "name": "Zócalo", "lat": 19.306, "lng": -98.187, "order": 1 },
        { "id": 2, "name": "Mercado", "lat": 19.308, "lng": -98.185, "order": 2 },
        { "id": 3, "name": "Volcanes", "lat": 19.320, "lng": -98.170, "order": 3 }
      ]
    }
  ]
}
```

### Ejemplo: `sync.php`

```
GET /combiapi/sync.php?client_version=0
```

Si el cliente tiene versión `0` y el servidor tiene `1`, retorna el payload completo de rutas y paradas. Si coinciden, retorna `{"status": "ok", "data": "up_to_date"}`.

---

## Base de datos MySQL

### Esquema

```sql
-- Rutas de transporte (datos públicos, cacheables)
CREATE TABLE rutas (
  id             INT AUTO_INCREMENT PRIMARY KEY,
  number_code    VARCHAR(10)  NOT NULL UNIQUE,
  name           VARCHAR(100) NOT NULL,
  color          VARCHAR(7)   NOT NULL,        -- hex, ej: #FF6D00
  description    TEXT,
  start_point    VARCHAR(100) NOT NULL,
  end_point      VARCHAR(100) NOT NULL,
  estimated_time INT          NOT NULL,        -- minutos
  is_active      TINYINT      NOT NULL DEFAULT 1,
  created_at     TIMESTAMP    DEFAULT CURRENT_TIMESTAMP,
  updated_at     TIMESTAMP    DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Paradas ordenadas por ruta
CREATE TABLE paradas (
  id             INT AUTO_INCREMENT PRIMARY KEY,
  route_id       INT          NOT NULL,
  name           VARCHAR(100) NOT NULL,
  latitude       DECIMAL(10,7) NOT NULL,
  longitude      DECIMAL(10,7) NOT NULL,
  order_in_route INT          NOT NULL,
  created_at     TIMESTAMP    DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (route_id) REFERENCES rutas(id) ON DELETE CASCADE
);

-- Usuarios (esquema listo, vacío en V1 — auth se implementa después)
CREATE TABLE usuarios (
  id            INT AUTO_INCREMENT PRIMARY KEY,
  email         VARCHAR(255) NOT NULL UNIQUE,
  username      VARCHAR(50)  NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  nombre        VARCHAR(100) NOT NULL,
  is_admin      TINYINT      NOT NULL DEFAULT 0,
  created_at    TIMESTAMP    DEFAULT CURRENT_TIMESTAMP,
  updated_at    TIMESTAMP    DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
```

### Datos actuales

**Rutas (3 filas):**

| id | number_code | name | color | start_point | end_point | estimated_time |
|----|-------------|------|-------|-------------|-----------|----------------|
| 1 | A | Centro → Volcanes | #FF6D00 | Zócalo de Chiautempan | Volcanes | 25 min |
| 2 | B | Ocotlán → Centro | #1E88E5 | Basílica de Ocotlán | Centro Tlaxcala | 20 min |
| 3 | C | (tercera ruta) | — | — | — | — |

**Paradas (9 filas):** 3 paradas por ruta, con coordenadas reales de la zona Chiautempan–Tlaxcala.

### Credenciales de desarrollo

| Campo | Valor |
|-------|-------|
| Usuario API | `dev_usr`@`127.0.0.1` |
| Permisos | SELECT, INSERT, UPDATE solamente |
| Contraseña | Más fuerte que el placeholder del repo |
| Root | `sudo mysql` (socket unix, sin contraseña) |

⚠️ La contraseña en `common.php` del repo es un placeholder. La contraseña real en el servidor es diferente y cumple con la política de `validate_password`. Antes de producción, mover a `getenv()`.

---

## Regla de sincronización

La app **nunca escribe** datos de rutas/paradas directamente a SQLite. Solo lee del cache local. El servidor empuja datos nuevos mediante `sync.php`. La app solo acepta un sync si:

1. La `schema_version` del servidor difiere de la versión local en `meta_sync`.
2. No hay actividad de usuario activa en ese momento.

Esto previene conflictos de escritura entre versiones de la app y actualizaciones del equipo.

---

## Estructura del proyecto

```
Proyecto_combi/                    ← raíz del repositorio git
├── README.md                      ← este archivo
├── aplicacion/
│   ├── combis_app/                ← app Flutter (lo único que se compila)
│   │   ├── pubspec.yaml
│   │   ├── lib/
│   │   │   ├── main.dart
│   │   │   ├── models/            ← Ruta, Parada (fromMap/toMap + fromJson)
│   │   │   ├── data/              ← seed_data.dart (fallback offline)
│   │   │   ├── database/          ← database_helper.dart (SQLite)
│   │   │   ├── services/          ← api_service.dart (en progreso)
│   │   │   ├── repositories/      ← route_repository.dart (en progreso)
│   │   │   ├── pages/             ← boot_page, home_page, etc. (pendiente)
│   │   │   ├── widgets/           ← map_widget, route_card (pendiente)
│   │   │   └── theme/             ← app_theme.dart (pendiente)
│   │   └── test/
│   └── docs/                      ← documentación del proyecto
│       ├── ARCHITECTURE.md
│       ├── Entorno_setup.md
│       ├── db_schema.md
│     
│       
├── server/                        ← mirror de /var/www/html/myapp/combiapi/
│   ├── common.php                 ← bootstrap, sendJson(), getMysqlConnection()
│   ├── check.php                  ← health check
│   ├── routes.php                 ← rutas + paradas embebidas
│   └── sync.php                   ← sincronización por schema_version
└── pruebas/                       ← scaffolding temporal — no es fuente de verdad
```

---

## Dependencias principales

```yaml
flutter_map: ^6.0.0         # Mapa OSM
latlong2: ^0.9.0             # Coordenadas
sqflite: ^2.3.0              # SQLite Android
sqflite_common_ffi: ^2.3.0   # SQLite Linux/Windows
http: ^1.1.0                 # Llamadas REST
provider: ^6.0.0             # State management (tentativo)
geolocator: ^10.0.0          # GPS (pendiente)
```

---

## Reglas del equipo

- **No renumerar IDs de rutas** sin migración que actualice las FKs en MySQL.
- Si una ruta está en desarrollo, poner `is_active = 0` en lugar de eliminarla.
- No agregar endpoints que salten `common.php` (bootstrap).
- Pull al inicio de cada sesión. Push frecuente. Commits descriptivos en español.
- *Ten cuidado con cambios al esquema de BD*: incrementar `dbVersion` en `DatabaseHelper` e implementar `onUpgrade`, el objetivo es intentar mantener nueestras bds actuales y solo ir migrando con cuidado los cambios o mejoras que se nos ocurran luego.

---

## Deudas técnicas conocidas

1. Contraseña MySQL hardcodeada en `common.php` — mover a `getenv()` antes de producción.
2. `BootPage` aún no construida — no hay UI de error si el seed falla.
3. `ApiService` sin timeout/retry más allá del básico `.timeout()`.
4. Provider no integrado — state se maneja con `setState` por ahora.
5. `applicationId` en `build.gradle` posiblemente sigue como `com.example.*` — cambiar antes de distribuir.

## 📖 Documentación Adicional

escriban comentarios en sus commits de manera descriptiva perras

- [Arquitectura del sistema](aplicacion/docs/ARCHITECTURE.md)
- [Schema de base de datos](aplicacion/docs/db_schema.md)
- [Guía de inicio del entorno](aplicacion/docs/Entorno_setup.md)


---