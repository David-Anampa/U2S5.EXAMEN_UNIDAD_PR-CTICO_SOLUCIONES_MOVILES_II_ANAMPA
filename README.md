# EXAMEN PRÁCTICO DE LA UNIDAD II

- **CURSO:** SI-988 SOLUCIONES MÓVILES II
- **AUTOR:** 2022074268 – Anampa Pancca, David Jordan
- **URL GITHUB:** [https://github.com/David-Anampa/U2S5.EXAMEN_UNIDAD_PR-CTICO_SOLUCIONES_MOVILES_II_ANAMPA.git](https://github.com/David-Anampa/U2S5.EXAMEN_UNIDAD_PR-CTICO_SOLUCIONES_MOVILES_II_ANAMPA.git)
- **TIPO DE EXAMEN:** 3
- **DOCENTE:** DR. OSCAR JUAN JIMENEZ FLORES
- **INSTITUCIÓN:** UNIVERSIDAD PRIVADA DE TACNA
- **LUGAR Y FECHA:** TACNA — PERÚ, 2026

---

## Historia de Usuario
> **Como** usuario de la app SITRA-Luz,  
> **quiero** decidir qué datos míos se usan y para qué, y tener la seguridad de que la app no envía ni registra más de lo necesario,  
> **para** proteger mi privacidad y garantizar el cumplimiento de normativas de protección de datos personales.

---

## Resumen de Casos Implementados (Tipo de Examen 3)

### Caso 1: Pantalla de Consentimiento (4 puntos)
- **Objetivo:** Permitir al usuario aceptar o rechazar por separado cada uso opcional de sus datos.
- **Implementación:**
  - Redirección obligatoria en el primer arranque hacia `/privacidad` antes del inicio de sesión mediante `GoRouter`.
  - Presenta dos interruptores opcionales: **«Analítica de uso»** y **«Envío de promocionales»**, apagados por defecto (`false`).
  - Botones de acción rápida: **«Aceptar todo»**, **«Rechazar todo»** y **«Confirmar mi elección»**.
  - Persistencia local con la versión de la política vigente (`"1.0"`) y la fecha/hora actual (`DateTime.now()`).
  - Acceso directo desde la barra compartida (`SitraAppBar`) y la pantalla de login para revisar o modificar la decisión guardada.

### Caso 2: Envío de Datos Necesarios al Servidor - Minimización (4 puntos)
- **Objetivo:** Garantizar que la petición al backend transporte únicamente los campos estrictamente necesarios.
- **Implementación:**
  - Seleccionada la petición de administración de usuarios clínicos (`UsuarioBorrador.toJson` y `UsuarioAdministrativo.toPeticion`).
  - La carga útil excluye datos que el perfil no gestiona (correo de Auth, ID interno del perfil, estado activo por acción separada, fechas de auditoría y nombres descriptivos derivados).
  - Si la petición incluyera coordenadas opcionales, se redondean y limitan a un máximo de tres decimales.
  - Registro en depuración del JSON exacto bajo la etiqueta `[PETICION]`.

#### Tabla de Minimización de Campos de la Entidad:
| Campo de la entidad | Se envía | Por qué |
| :--- | :---: | :--- |
| **nombres**, **apellidos** | **Sí** | El servidor los guarda en el perfil del usuario. |
| **usuario** (`nombre_usuario`) | **Sí** | El servidor valida unicidad y lo persiste. |
| **cargo** | **Sí** | Define la responsabilidad y si aplica gestión de kits. |
| **rol** | **Sí** | Asigna los permisos en la base de datos de Supabase. |
| **areas** | **Sí** | Asigna las áreas de trabajo autorizadas para el usuario. |
| **puedeGestionarKits** | **Sí** | Permiso específico que el servidor valida y almacena. |
| **colegioCodigo, numeroColegiatura, especialidadCodigo** | **Sí** | Datos profesionales clínicos validados por la RPC. |
| **id** | **No** (va en `p_id`) | Identifica el registro a editar; no es parte del perfil. |
| **correo** | **No** | Pertenece a Supabase Auth; no se edita en este perfil. |
| **activo** | **No** | Se cambia por una acción administrativa independiente (`ESTADO`). |
| **nombreAnterior** | **No** | Campo histórico de migración; el backend ya no lo usa. |
| **creado**, **actualizado** | **No** | Fechas de auditoría fijadas automáticamente por el servidor. |
| **colegioNombre, especialidadNombre** | **No** | Son etiquetas de interfaz; el servidor las deriva del código. |
| **coordenadas** | **No** | La gestión de usuarios y personal clínico no requiere ubicación GPS. |

### Caso 3: Registro de Logs sin Datos Personales (4 puntos)
- **Objetivo:** Ningún registro emitido por la app permite identificar directa ni indirectamente al usuario.
- **Implementación:**
  - Servicio centralizado `RegistroApp` con método estático `enmascarar()`.
  - Expresiones regulares que enmascaran correos (`***@***`), celulares peruanos de 9 dígitos (`*********`) y números de DNI de 8 dígitos (`********`).
  - La analítica solo se registra si el usuario aceptó «Analítica de uso» (`RegistroApp.analiticaPermitida`).
  - Todas las salidas del proyecto reemplazaron `print` y `debugPrint` directos por `RegistroApp.log()`.
  - Datos de prueba en la acción de guardar consentimiento para comprobación en consola.

### Caso 4: Tres Pruebas Unitarias del Consentimiento (4 puntos)
- **Objetivo:** Comprobación del consentimiento sin emulador ni red mediante versiones simuladas (`AlmacenSimulado` y `AnaliticaSimulada`).
- **Pruebas en `test/consentimiento_test.dart`:**
  - **Prueba (a):** Sin decisión guardada, los dos usos opcionales están apagados (`false`).
  - **Prueba (b):** Al aceptar solo «Analítica de uso», queda encendida solo esa y se guarda la versión `"1.0"` con fecha.
  - **Prueba (c):** Tras retirar «Analítica de uso», un evento de la app no llega a la analítica (lista vacía).
- **Ejecución:** `flutter test test/consentimiento_test.dart` (100% PASS).

### Caso 5: Dos Pruebas Unitarias de Enmascarado y de Envío Mínimo (4 puntos)
- **Objetivo:** Comprobación automatizada con datos fijos de que el log y la petición no llevan datos de más.
- **Pruebas en `test/enmascarado_minimo_test.dart`:**
  - **Prueba (a):** El texto `"cliente ana@correo.com cel 987654321 dni 45678912"` sale como `"cliente ***@*** cel ********* dni ********"` y sin los valores originales.
  - **Prueba (b):** Una entidad de prueba convertida a la petición no contiene los campos excluidos del ítem 2, y sus coordenadas tienen como máximo tres decimales (`-18.012` y `-70.255`).
- **Ejecución:** `flutter test test/enmascarado_minimo_test.dart` (100% PASS).

---

## Archivos del Proyecto Móvil Afectados y Nuevos

### Nuevos Componentes y Módulos
1. `app/lib/core/logging/registro_app.dart`:
   - Servicio centralizado de enmascaramiento y logging seguro con control de analítica.
2. `app/lib/features/privacidad/data/consentimiento_repository.dart`:
   - Repositorio y modelo de persistencia local del consentimiento (versión y fecha).
   - Abstracción `AlmacenClaveValor` para permitir simulación en pruebas unitarias.
3. `app/lib/features/privacidad/presentation/consentimiento_viewmodel.dart`:
   - `ChangeNotifier` que gestiona el estado de privacidad y notifica al enrutador.
4. `app/lib/features/privacidad/presentation/privacidad_view.dart`:
   - Vista responsiva de consentimiento con switches, tarjetas explicativas y botones de decisión rápida.
5. `app/test/consentimiento_test.dart`:
   - Pruebas unitarias completas del Caso 4 con mocks en memoria.
6. `app/test/enmascarado_minimo_test.dart`:
   - Pruebas unitarias completas del Caso 5 para validación de regex y minimización.
7. `app/test/registro_app_test.dart`:
   - Pruebas unitarias auxiliares de enmascaramiento con formatos variados.

### Archivos Modificados
1. `app/lib/core/routes/app_router.dart`:
   - Ruta `/privacidad` y redirección en el primer arranque si no hay decisión tomada.
2. `app/lib/main.dart`:
   - Carga inicial del repositorio de consentimiento y suministro vía `MultiProvider`.
3. `app/lib/core/widgets/sitra_app_bar.dart`:
   - Botón directo de acceso a «Privacidad» en la barra de aplicación compartida.
4. `app/lib/features/administracion/domain/usuario_borrador.dart`:
   - Conversión minimizada `toJson()` excluyendo campos no requeridos por la RPC.
5. `app/lib/features/administracion/data/usuarios_repository.dart`:
   - Método `toPeticion()` en `UsuarioAdministrativo` y registro seguro de peticiones `[PETICION]`.
6. `app/lib/core/network/diagnostico_red.dart`:
   - Redirección de logs a `RegistroApp.log()` para evitar filtrado de excepciones con datos sensibles.
7. `app/lib/core/services/notification_service.dart`:
   - Enmascaramiento de tokens y cargas útiles de notificaciones push.
8. `app/lib/features/almacen/data/datasources/almacen_remote_datasource.dart`:
   - Reemplazo de llamadas a `debugPrint` por `RegistroApp.log()`.
9. `app/lib/features/auth/data/datasources/auth_remote_datasource.dart`:
   - Registro enmascarado en flujo de autenticación y diagnóstico de red.

---

## Comandos para Ejecución de Pruebas

Desde el directorio `app`:

```bash
# Ejecutar Caso 4: Pruebas unitarias de consentimiento
flutter test test/consentimiento_test.dart

# Ejecutar Caso 5: Pruebas unitarias de enmascarado y envío mínimo
flutter test test/enmascarado_minimo_test.dart

# Ejecutar todas las pruebas unitarias del proyecto
flutter test
```
