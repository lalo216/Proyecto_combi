// Disciplina:
//   - Páginas hacen `on ApiException catch (e)` / `on TimeoutException catch (e)`.
//     NO usar `catch (e)` en las páginas: errores de programación (TypeError,
//     AssertionError, StateError) deben subir hasta los handlers globales en
//     main.dart, no maquillarse como "Sin conexión".
//   - reportError() SIEMPRE reporta a FlutterError.reportError. El SnackBar
//     es feedback UX adicional, no reemplaza el log.
//   - Si ves "Error inesperado" en pantalla, hay un bug — el fallback existe
//     sólo para no dejar al usuario sin señal mientras el log sale en consola.

import 'package:flutter/material.dart';
import '../services/api_service.dart';

void reportError(BuildContext ctx, Object e, {String? hint, StackTrace? stack}) {
  FlutterError.reportError(FlutterErrorDetails(
    exception: e,
    stack: stack ?? StackTrace.current,
    library: 'combis_app',
    context: hint == null ? null : ErrorDescription(hint),
  ));

  if (!ctx.mounted) return;
  final msg = switch (e) {
    OfflineException _ => 'Sin conexión',
    ApiException e => e.message,
    _ => 'Error inesperado',
  };
  ScaffoldMessenger.of(ctx).showSnackBar(
    SnackBar(
      content: Text(msg),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 3),
    ),
  );
}
