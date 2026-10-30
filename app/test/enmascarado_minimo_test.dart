import 'package:flutter_test/flutter_test.dart';
import 'package:sitra_luz/core/logging/registro_app.dart';
import 'package:sitra_luz/features/administracion/data/usuarios_repository.dart';

void main() {
  group('Caso 5 - Pruebas unitarias de enmascarado y de envío mínimo', () {
    test(
      '(a) el texto de prueba sale enmascarado sin correo, celular ni DNI originales',
      () {
        const entrada = 'cliente ana@correo.com cel 987654321 dni 45678912';
        final salida = RegistroApp.enmascarar(entrada);

        // Sale enmascarado con las máscaras esperadas
        expect(salida, 'cliente ***@*** cel ********* dni ********');

        // Sin ana@correo.com, 987654321 ni 45678912
        expect(salida.contains('ana@correo.com'), isFalse);
        expect(salida.contains('987654321'), isFalse);
        expect(salida.contains('45678912'), isFalse);
      },
    );

    test(
      '(b) la entidad convertida a la petición no contiene campos excluidos del ítem 2 y coordenadas tienen máx 3 decimales',
      () {
        // 1. Entidad completa con todos los campos (incluyendo los que deben excluirse)
        final entidad = UsuarioAdministrativo(
          id: 'usr-uuid-12345',
          usuario: 'asalas',
          nombres: 'Ana',
          apellidos: 'Salas',
          nombreAnterior: 'Ana Salas Historico',
          correo: 'ana.salas@clinicalaluz.pe',
          cargo: 'Enfermera Especialista',
          rol: 'ENFERMERIA',
          areas: const ['EMERGENCIA', 'FARMACIA'],
          activo: true,
          puedeGestionarKits: true,
          creado: DateTime(2026, 1, 15, 10, 30),
          actualizado: DateTime(2026, 2, 20, 14, 45),
          colegioCodigo: 'CEP',
          numeroColegiatura: '98765',
          especialidadCodigo: 'ENF-PED',
          colegioNombre: 'Colegio de Enfermeros del Perú',
          especialidadNombre: 'Enfermería Pediátrica',
        );

        // Coordenadas con más de tres decimales (-18.0123456, -70.2547891)
        const latOriginal = -18.0123456;
        const lngOriginal = -70.2547891;

        // Conversión de la entidad a la petición
        final peticion = entidad.toPeticion(
          latitud: latOriginal,
          longitud: lngOriginal,
        );

        // Comprobación de minimización: campos excluidos según el ítem 2
        expect(peticion.containsKey('id'), isFalse);
        expect(peticion.containsKey('correo'), isFalse);
        expect(peticion.containsKey('email'), isFalse);
        expect(peticion.containsKey('nombreAnterior'), isFalse);
        expect(peticion.containsKey('nombre'), isFalse);
        expect(peticion.containsKey('activo'), isFalse);
        expect(peticion.containsKey('creado'), isFalse);
        expect(peticion.containsKey('created_at'), isFalse);
        expect(peticion.containsKey('actualizado'), isFalse);
        expect(peticion.containsKey('updated_at'), isFalse);
        expect(peticion.containsKey('colegioNombre'), isFalse);
        expect(peticion.containsKey('colegio_nombre'), isFalse);
        expect(peticion.containsKey('especialidadNombre'), isFalse);
        expect(peticion.containsKey('especialidad_nombre'), isFalse);

        // Campos que SÍ deben viajar en la petición
        expect(peticion['nombres'], 'Ana');
        expect(peticion['apellidos'], 'Salas');
        expect(peticion['nombre_usuario'], 'asalas');
        expect(peticion['cargo'], 'Enfermera Especialista');
        expect(peticion['rol'], 'ENFERMERIA');
        expect(peticion['areas'], ['EMERGENCIA', 'FARMACIA']);
        expect(peticion['puede_gestionar_kits'], isTrue);
        expect(peticion['colegio_codigo'], 'CEP');
        expect(peticion['numero_colegiatura'], '98765');
        expect(peticion['especialidad_codigo'], 'ENF-PED');

        // Comprobación de coordenadas: viajan con como máximo 3 decimales
        final latEnviada = peticion['latitud'] as double;
        final lngEnviada = peticion['longitud'] as double;

        expect(latEnviada, -18.012);
        expect(lngEnviada, -70.255);

        final partesLat = latEnviada.toString().split('.');
        final decimalesLat = partesLat.length > 1 ? partesLat[1].length : 0;
        expect(decimalesLat, lessThanOrEqualTo(3));

        final partesLng = lngEnviada.toString().split('.');
        final decimalesLng = partesLng.length > 1 ? partesLng[1].length : 0;
        expect(decimalesLng, lessThanOrEqualTo(3));
      },
    );
  });
}
