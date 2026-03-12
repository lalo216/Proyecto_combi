# Combis App —  Tlaxcala 🚐

> Una guía de transporte público moderna para las rutas de combis en un estado peque de México. Desarrollada con Flutter para dispositivos móviles.

Este proyecto tiene como objetivo digitalizar las rutas de transporte público, permitiendo a los usuarios visualizar recorridos en tiempo real sobre un mapa real y encontrar la mejor opción para su traslado.

---

##  Inicio Rápido

### Requisitos Previos

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (Canal stable sugerido)
- VS Code con extensiones de Flutter/Dart e importantemente el paquete de extensiones de C++
- Git instalado
- Flutter y dart en tu path para usar debugeo desde la terminal
- Un dispositivo físico o emulador (Android preferido, soporte experimental para Linux Desktop, en terminos de emuladores recomendamos bluestacks o waydroid)

### Instalación y Ejecución

1. **Clonar el repositorio:**
   ```bash
   git clone *link del repositorio*combisv3.git
   cd combisv3
   ```

2. **Obtener dependencias:**
   ```bash
   flutter pub get
   ```

3. **Ejecutar la aplicación:**
   ```bash
   flutter run -d web-server --web-port=3520 
   ```
El último hace que tu app siempre este en localhost:3520
---

##  Stack Tecnológico - Para nada final.

- **Framework:** [Flutter](https://flutter.dev) (UI)
- **Mapas:** [flutter_map](https://pub.dev/packages/flutter_map) + OpenStreetMap
- **Tipografía:** [Google Fonts](https://pub.dev/packages/google_fonts) (Inter)
- **Persistencia:** SQLite vía `sqflite` (Actualmente en preparación para reintegración)

---

## 📂 Estructura del Proyecto 📂

Para los desarrolladores que se integran al equipo, aquí está la organización principal:

- `lib/data/`: Datos estáticos temporales (capas de ruta).
- `lib/pages/`: Vistas principales (Inicio, Rutas, Perfil).
- `lib/widgets/`: Componentes reutilizables, como el `MapWidget`.
- `lib/theme/`: Sistema de diseño "Vibrant Sunset" (colores y estilos globales).
- `lib/utils/`: Utilidades de log (`debugLog`) y formateo.

---

## Estado del Proyecto

Actualmente nos encontramos con algo asi:
- **Mapa Integrado:** El mapa interactivo ahora reside en la pantalla de Inicio.
- **Soporte de Capas:** Visualización de rutas (polilíneas) y puntos de parada.
- **Base de Datos:** La capa de SQLite está temporalmente deshabilitada para agilizar el desarrollo de la UI. Los datos actuales en `lib/data/route_data.dart` son estáticos y sirven como arquitectura para la futura conexión con la BD.

---

## 📖 Documentación Adicional
 no hay

## 👥 Equipo

Si tienes dudas sobre la implementación de los mapas o la lógica de las rutas, consulta los comentarios en el código (todos traducidos al español para mejor soporte del equipo).
