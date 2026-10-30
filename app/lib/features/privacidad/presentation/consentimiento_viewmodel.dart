import 'package:flutter/foundation.dart';

import '../../../core/logging/registro_app.dart';
import '../data/consentimiento_repository.dart';

/// Estado del consentimiento; el router lo escucha para forzar la pantalla
/// de privacidad la primera vez que se abre la app.
class ConsentimientoViewModel extends ChangeNotifier {
  final ConsentimientoRepository _repository;
  Consentimiento? _decision;

  ConsentimientoViewModel(this._repository) {
    _decision = _repository.leer();
    RegistroApp.analiticaPermitida = _decision?.analitica ?? false;
  }

  Consentimiento? get decision => _decision;
  bool get decidido => _decision != null;

  /// Sin decisión guardada, ambos usos opcionales están apagados.
  bool get analitica => _decision?.analitica ?? false;
  bool get promocionales => _decision?.promocionales ?? false;

  Future<void> guardar({
    required bool analitica,
    required bool promocionales,
  }) async {
    _decision = await _repository.guardar(
      analitica: analitica,
      promocionales: promocionales,
    );
    // La analítica solo se activa si el usuario aceptó «Analítica de uso».
    RegistroApp.analiticaPermitida = _decision!.analitica;
    // EVIDENCIA (caso 3): datos de prueba que deben salir enmascarados en el log.
    RegistroApp.log(
      'Consentimiento guardado | correo=usuario.prueba@correo.com '
      'celular=987654321 dni=12345678',
    );
    RegistroApp.evento('consentimiento_guardado', {
      'analitica': analitica,
      'promocionales': promocionales,
    });
    notifyListeners();
  }
}
