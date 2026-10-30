import 'package:flutter_test/flutter_test.dart';
import 'package:sitra_luz/core/logging/registro_app.dart';

void main() {
  test('enmascara correo, celular de 9 dígitos y DNI', () {
    final salida = RegistroApp.enmascarar(
      'correo=usuario.prueba@correo.com celular=987654321 dni=12345678',
    );
    expect(salida, 'correo=***@*** celular=********* dni=********');
  });

  test('celular con separadores y mensajes sin datos personales', () {
    expect(RegistroApp.enmascarar('cel 987 654 321'), 'cel *********');
    expect(RegistroApp.enmascarar('Sesión iniciada'), 'Sesión iniciada');
  });

  test('la analítica está apagada por defecto', () {
    expect(RegistroApp.analiticaPermitida, isFalse);
  });
}
