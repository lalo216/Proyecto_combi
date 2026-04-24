# Combis Tlax - Arquitectura seleccionada y más
**Escala:** servidor - API - REST - Dual-DB

---

## 1.- Proposito de este documento

Vamos a requerir construir una API, ademas de definir los servicios y limites del sistema en cargo de manejar cambios de
información relacionados con 1) Lo especial de la app como rutas/paradas/dibujar en el mapa y 2) Los usuarios, sus preferencias u otra información sensible. 

---

## ¿Como le haremos?

Propongo la siguiente arquitectura a alto nivel:

vista en -[arquitectura](aplicacion/docs/ARCHITECTURE.md)

## La lógica 
**SQLite** Mantiene información que podemos brindar al usuario sin pedir autenticidad, excelente para cachear y leer, podemos ¨enviar" un snapshot de esta bd de respaldo para uso _offline_. Info personal identificable _no_ vive aqui, por lo que deberiamos poder incluso eliminarla y resemblar sin perdida significativa ni lentitud perceptible por el usuario.

**MySQL** Mantiene todo lo sensible, eventualmente credenciales de usuarios, nosotros como admins, posiblemente la tabla de favoritos. Nunca recae en cache para el cliente. 

## El gol

La primer version de esta arquitectura debera probar que la app puede comunicarse con el servidor desde un emulador con waydroid, ademas debe implementar lo que ya tenemos en respeto a poder demostrar un mapa y dibujar encima de el. Para este demo, tendremos como gol instalar las dbs y rescatar principalmente de la local para dibujar las rutas a base de que el programa toma el punto final de una ruta y dibuja hacia "atras" tocando cada parada asociada en orden hasta llegar al punto de inicio de la ruta.

## Requisitos

**Endpoints y requisitos**
Cada endpoint debe regresar la misma plantilla de informacion (json envelope):

```json
{
  "status": "ok" | "error",
  "data": { ... } | null,
  "meta": {
    "timestamp": "2026-03-24T12:00:00+00:00",
    "version": "1.0"
  },
  "message": "Cadena leible (errores solamente)"
}
```
Cual sera leido por la app, acorde a principios de REST de arriba hacia abajo, usando status para entender su siguiente paso. No estoy seguro para que es message todavia. Pero, no se debe agregar endpoints que salten el previo cheque, conocido como 'bootstrap.php' adentro del servidor.

En V1 tendremos 3 o mas endpoints que haste cuenta funcionan como servicios:
rutas.php
sync.php


**Paritad y sincronizacion**

En general es dificil crear una buena app con un CRUD que no cause problemas entre los desarrolladores y usuarios, dessarrolladores y ellos mismos, etc. Para anticiparlo
estaremos introduciendo el restringio de diseño más importante para nuestra app multi-usuario, multi-version, _seguridad en syncronizidad_

**La regla:** La app nunca modifica información de ida relacionada con la db. Solamente lee del cache local, el servidor empuja data nueva a la app mediante otro endpoint (sync endpoitn). La app debe solo acceptar un sync si:

1. Recive una version o "checksum" del servidor differente del que tiene localmente.
2. No hay actividad de usuario interactuando con el estado local.

1.-Es cumplido por el endpoint de rutas (actualmente) cual incluye un "schema_version" en la metadata de su respuesta. Un mismatch inicia resincronizacion, Una actualizacion parcial (admin agrega una parada) actualiza la version, solo cuando este en el foreground, no en pleno uso de su sessión maso.

### Flujo posible

1. Con primer instalacion, la app siembra su db local usando SeedData.dart (data de starter)
2. Cuando la app obtiene una connecion exitocsa, llama el futuro endpoint en rutas.php para comparar versiones de la db.
3. Si las versiones no coincide, la app reconstrue su cache a base de la data del servidor.
4. Si las versiones coinciden, no se requiere sincronizacion.
Esto significa que, con cada nueva sincronizacion la aplicacion jala informacion frezca mientras que el usuario todavia puede resolver sus rutas favoritas, porque los ids de las rutas son constantes en cada resembreo.
Como dessarrolladores, no se deberia empujar un cambio a la db que elimine o renumere el id de una ruta sin migracion apropiada, que sea constante con las FKs en la bd de mysql. Si se esta activamente trabajando con una ruta, cambia su estado de activo = 0 hasta finalizar.

### Actualidad 14-04-26

La api esta más avanzada que nunca, por el momento necesitare introducir los dispositivos del equipo a la red privada que estoy usando para compartirla, pero en el futuro se espera que esta tenga su propio dominio. Es realmente interesante, pero no tiene mucho que ver con nuestro desarrollo en flutter (La api fue hecha en php con principios de REST), por lo que no la agregare al repositorio todavia. Como habia estado documentando consiste de unos endpoints y biblioteca de utilidades, mantiene todo en una base de mysql, asi es, la bd mysqlite termina en teoría solo existiendo en los dispositivos del usuario.

Pruebas: 

```bash
󰣇 ~ ❯ 
curl https://mechyserver.xxx.no.jaja/combiapi/check.php                                                    #Nota, cuidado con nuestros dominios. Ahorita la única proteccion que tiene es estar atras de mi red, luego es posible que un tunel de cloudflare nos facilite todo.
{
    "status": "ok",
    "schema_version": 1,
    "data": {
        "server": {
            "hostname": "mechyserver",
            "php_version": "8.3.6",
            "timestamp": "2026-04-15T05:01:04+00:00"
        },
        "mysql": {
            "status": "ok"
        }
    },
    "meta": {
        "timestamp": "2026-04-15T05:01:04+00:00",
        "version": "1.0"
    }
}⏎                             
```