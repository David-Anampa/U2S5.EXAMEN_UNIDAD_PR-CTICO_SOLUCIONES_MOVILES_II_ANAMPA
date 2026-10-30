import 'package:shared_preferences/shared_preferences.dart';

/// Decisión de consentimiento guardada en el teléfono.
class Consentimiento {
  final bool analitica;
  final bool promocionales;
  final String versionPolitica;
  final DateTime fecha;

  const Consentimiento({
    required this.analitica,
    required this.promocionales,
    required this.versionPolitica,
    required this.fecha,
  });
}

/// Almacenamiento clave-valor del teléfono. Es una interfaz para poder
/// reemplazarlo por una versión en memoria en las pruebas unitarias.
abstract class AlmacenClaveValor {
  bool? leerBool(String clave);
  String? leerTexto(String clave);
  Future<void> guardarBool(String clave, bool valor);
  Future<void> guardarTexto(String clave, String valor);
}

/// Implementación real sobre SharedPreferences.
class AlmacenSharedPreferences implements AlmacenClaveValor {
  final SharedPreferences _prefs;
  AlmacenSharedPreferences(this._prefs);

  @override
  bool? leerBool(String clave) => _prefs.getBool(clave);

  @override
  String? leerTexto(String clave) => _prefs.getString(clave);

  @override
  Future<void> guardarBool(String clave, bool valor) =>
      _prefs.setBool(clave, valor);

  @override
  Future<void> guardarTexto(String clave, String valor) =>
      _prefs.setString(clave, valor);
}

/// Persiste localmente la decisión de privacidad.
class ConsentimientoRepository {
  /// Versión vigente de la política de privacidad.
  static const String versionVigente = '1.0';

  static const _kAnalitica = 'consent_analitica';
  static const _kPromocionales = 'consent_promocionales';
  static const _kVersion = 'consent_version_politica';
  static const _kFecha = 'consent_fecha';

  final AlmacenClaveValor _almacen;
  ConsentimientoRepository(this._almacen);

  /// Devuelve la decisión guardada o null si el usuario aún no decidió.
  Consentimiento? leer() {
    final fecha = DateTime.tryParse(_almacen.leerTexto(_kFecha) ?? '');
    final version = _almacen.leerTexto(_kVersion);
    if (fecha == null || version == null) return null;
    return Consentimiento(
      analitica: _almacen.leerBool(_kAnalitica) ?? false,
      promocionales: _almacen.leerBool(_kPromocionales) ?? false,
      versionPolitica: version,
      fecha: fecha,
    );
  }

  /// Guarda la decisión junto con la versión de la política y la fecha.
  Future<Consentimiento> guardar({
    required bool analitica,
    required bool promocionales,
  }) async {
    final decision = Consentimiento(
      analitica: analitica,
      promocionales: promocionales,
      versionPolitica: versionVigente,
      fecha: DateTime.now(),
    );
    await _almacen.guardarBool(_kAnalitica, decision.analitica);
    await _almacen.guardarBool(_kPromocionales, decision.promocionales);
    await _almacen.guardarTexto(_kVersion, decision.versionPolitica);
    await _almacen.guardarTexto(_kFecha, decision.fecha.toIso8601String());
    return decision;
  }
}
