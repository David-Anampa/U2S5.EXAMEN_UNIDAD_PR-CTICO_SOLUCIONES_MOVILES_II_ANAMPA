import 'package:flutter/foundation.dart';

/// Destino de los eventos de analítica. Es una interfaz para poder simularlo
/// en las pruebas; por defecto escribe en el log enmascarado.
abstract class Analitica {
  void registrar(String nombre, Map<String, Object?> parametros);
}

/// La app no usa un servicio externo: los eventos van al log enmascarado.
class AnaliticaEnLog implements Analitica {
  const AnaliticaEnLog();

  @override
  void registrar(String nombre, Map<String, Object?> parametros) =>
      RegistroApp.log('[ANALITICA] $nombre $parametros');
}

/// Único punto por el que la app escribe en el log y registra analítica.
///
/// - Todo mensaje pasa por [enmascarar]: correos, celulares de 9 dígitos y DNI
///   de 8 dígitos nunca salen en claro.
/// - Los eventos de analítica solo se escriben si el usuario aceptó
///   «Analítica de uso» ([analiticaPermitida]).
/// - Ninguna otra parte del código debe llamar a `print` ni a `debugPrint`.
class RegistroApp {
  RegistroApp._();

  /// Se actualiza desde el consentimiento guardado. Apagado por defecto.
  static bool analiticaPermitida = false;

  static final _correo = RegExp(
    r'[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}',
  );
  // 9 dígitos, opcionalmente separados en grupos de 3 (987 654 321 / 987-654-321).
  static final _celular = RegExp(r'(?<!\d)\d{3}[ \-]?\d{3}[ \-]?\d{3}(?!\d)');
  static final _dni = RegExp(r'(?<!\d)\d{8}(?!\d)');

  /// Reemplaza datos personales por máscaras. El orden importa: primero el
  /// correo (puede contener dígitos), luego celular (9) y por último DNI (8).
  static String enmascarar(String texto) => texto
      .replaceAllMapped(_correo, (m) => '***@***')
      .replaceAllMapped(_celular, (m) => '*********')
      .replaceAllMapped(_dni, (m) => '********');

  /// Escribe un mensaje en el log, siempre enmascarado.
  static void log(String mensaje) {
    if (!kDebugMode) return;
    debugPrint(enmascarar(mensaje));
  }

  /// Destino de analítica; las pruebas lo reemplazan por una versión simulada.
  static Analitica destinoAnalitica = const AnaliticaEnLog();

  /// Registra un evento de analítica solo si el usuario aceptó «Analítica de
  /// uso». Si no la aceptó (o la retiró), el evento no llega al destino.
  static void evento(String nombre, [Map<String, Object?> parametros = const {}]) {
    if (!analiticaPermitida) return;
    destinoAnalitica.registrar(nombre, parametros);
  }
}
