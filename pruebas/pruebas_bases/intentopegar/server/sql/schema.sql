-- ============================================
-- Schema MySQL para Combis App V1
-- Ejecutar en el servidor: mysql -u root -p < schema.sql
-- ============================================

CREATE DATABASE IF NOT EXISTS combis_db
  CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE combis_db;

-- ────────────────────────────────────────────
-- Tablas: rutas y paradas (cacheable — datos de la innovación)
-- ────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS rutas (
  id             INT AUTO_INCREMENT PRIMARY KEY,
  number_code    VARCHAR(10)  NOT NULL UNIQUE,
  name           VARCHAR(100) NOT NULL,
  color          VARCHAR(7)   NOT NULL,
  description    TEXT,
  start_point    VARCHAR(100) NOT NULL,
  end_point      VARCHAR(100) NOT NULL,
  estimated_time INT          NOT NULL,
  is_active      TINYINT      NOT NULL DEFAULT 1,
  created_at     TIMESTAMP    DEFAULT CURRENT_TIMESTAMP,
  updated_at     TIMESTAMP    DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS paradas (
  id             INT AUTO_INCREMENT PRIMARY KEY,
  route_id       INT          NOT NULL,
  name           VARCHAR(100) NOT NULL,
  latitude       DECIMAL(10,7) NOT NULL,
  longitude      DECIMAL(10,7) NOT NULL,
  order_in_route INT          NOT NULL,
  created_at     TIMESTAMP    DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (route_id) REFERENCES rutas(id) ON DELETE CASCADE
);

-- ────────────────────────────────────────────
-- Tabla: usuarios (segura — NO se cachea en la app)
-- Schema listo pero vacío en V1. Auth se implementa después.
-- ────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS usuarios (
  id            INT AUTO_INCREMENT PRIMARY KEY,
  email         VARCHAR(255) NOT NULL UNIQUE,
  username      VARCHAR(50)  NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  nombre        VARCHAR(100) NOT NULL,
  is_admin      TINYINT      NOT NULL DEFAULT 0,
  created_at    TIMESTAMP    DEFAULT CURRENT_TIMESTAMP,
  updated_at    TIMESTAMP    DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);


INSERT INTO rutas (number_code, name, color, description, start_point, end_point, estimated_time)
VALUES
  ('A', 'Centro → Volcanes', '#FF6D00', 'Ruta principal del centro a la zona de Volcanes', 'Zócalo de Chiautempan', 'Volcanes', 25),
  ('B', 'Ocotlán → Centro',  '#1E88E5', 'Conecta la Basílica de Ocotlán con el centro de Tlaxcala', 'Basílica de Ocotlán', 'Centro Tlaxcala', 20);

INSERT INTO paradas (route_id, name, latitude, longitude, order_in_route)
VALUES
  (1, 'Zócalo',     19.3060000, -98.1870000, 1),
  (1, 'Mercado',    19.3080000, -98.1850000, 2),
  (1, 'Volcanes',   19.3200000, -98.1700000, 3),
  (2, 'Basílica',   19.3140000, -98.2340000, 1),
  (2, 'Av. Juárez', 19.3120000, -98.2200000, 2),
  (2, 'Centro',     19.3100000, -98.2080000, 3);

-- ============================================
-- Crear usuario para la API (cambiar contraseña en producción)
-- ============================================
-- CREATE USER IF NOT EXISTS 'combis_user'@'localhost' IDENTIFIED BY 'combis_pass';
-- GRANT SELECT, INSERT, UPDATE, DELETE ON combis_db.* TO 'combis_user'@'localhost';
-- FLUSH PRIVILEGES;

-- ### 5.2 HTTP Status Codes
-- | Code | Meaning in this API |
-- |------|---------------------|
-- | `200` | Success (including degraded health — see `status` field) |
-- | `400` | Bad request — invalid params |
-- | `401` | Unauthenticated (future auth) |
-- | `403` | Forbidden — valid token, wrong role |
-- | `404` | Resource not found |
-- | `405` | Wrong HTTP method |
-- | `429` | Rate limited (future) |
-- | `500` | Server fault — always returns generic JSON, never HTML |

-- MySQL — Principle of Least Privilege

-- Create a dedicated API user with minimum permissions. Run this once:

-- ```sql
-- CREATE USER 'combis_api'@'localhost' IDENTIFIED BY 'strong_password_here';
-- GRANT SELECT, INSERT, UPDATE ON combis_db.rutas    TO 'combis_api'@'localhost';
-- GRANT SELECT, INSERT, UPDATE ON combis_db.paradas  TO 'combis_api'@'localhost';
-- -- usuarios added when auth is implemented
-- FLUSH PRIVILEGES;
-- ```

-- Never use `root` in application code. Never grant `DROP` or `ALTER` to the API user.