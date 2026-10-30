import 'package:flutter_test/flutter_test.dart';
import 'package:sitra_luz/core/logging/registro_app.dart';
import 'package:sitra_luz/features/privacidad/data/consentimiento_repository.dart';
import 'package:sitra_luz/features/privacidad/presentation/consentimiento_viewmodel.dart';

/// Almacenamiento simulado en memoria: reemplaza a SharedPreferences, así las
/// pruebas no necesitan emulador ni teléfono.
class AlmacenSimulado implements AlmacenClaveValor {
  final Map<String, Object> datos = {};

  @override
  bool? leerBool(String clave) => datos[clave] as bool?;

  @override
  String? leerTexto(String clave) => datos[clave] as String?;

  @override
  Future<void> guardarBool(String clave, bool valor) async =>
      datos[clave] = valor;

  @override
  Future<void> guardarTexto(String clave, String valor) async =>
      datos[clave] = valor;
}

/// Analítica simulada: guarda los eventos que le llegan, sin red ni servicio.
class AnaliticaSimulada implements Analitica {
  final List<String> eventos = [];

  @override
  void registrar(String nombre, Map<String, Object?> parametros) =>
      eventos.add(nombre);
}

void main() {
  late AlmacenSimulado almacen;
  late AnaliticaSimulada analitica;
  late ConsentimientoViewModel consentimiento;

  setUp(() {
    almacen = AlmacenSimulado();
    analitica = AnaliticaSimulada();
    RegistroApp.destinoAnalitica = analitica;
    consentimiento = ConsentimientoViewModel(ConsentimientoRepository(almacen));
  });

  tearDown(() {
    RegistroApp.destinoAnalitica = const AnaliticaEnLog();
    RegistroApp.analiticaPermitida = false;
  });

  test('(a) sin decisión guardada, los dos usos opcionales están apagados', () {
    expect(consentimiento.decidido, isFalse);
    expect(consentimiento.analitica, isFalse);
    expect(consentimiento.promocionales, isFalse);
  });

  test('(b) al aceptar solo analítica, solo esa queda encendida y se guarda la versión 1.0', () async {
    await consentimiento.guardar(analitica: true, promocionales: false);

    expect(consentimiento.analitica, isTrue);
    expect(consentimiento.promocionales, isFalse);
    expect(consentimiento.decision!.versionPolitica, '1.0');
    // Quedó guardado en el almacenamiento (simulado), con la fecha.
    final guardado = ConsentimientoRepository(almacen).leer()!;
    expect(guardado.analitica, isTrue);
    expect(guardado.promocionales, isFalse);
    expect(guardado.versionPolitica, '1.0');
  });

  test('(c) tras retirar analítica, un evento de la app no llega a la analítica', () async {
    await consentimiento.guardar(analitica: true, promocionales: false);
    analitica.eventos.clear();

    RegistroApp.evento('pantalla_vista');
    expect(analitica.eventos, ['pantalla_vista']); // con permiso sí llega

    await consentimiento.guardar(analitica: false, promocionales: false);
    analitica.eventos.clear();

    RegistroApp.evento('pantalla_vista');
    expect(analitica.eventos, isEmpty); // sin permiso no llega
  });
}
