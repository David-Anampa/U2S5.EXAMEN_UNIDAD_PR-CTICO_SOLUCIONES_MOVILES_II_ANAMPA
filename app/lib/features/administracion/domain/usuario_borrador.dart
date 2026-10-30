/// Datos editables de un usuario, tal como los envía el formulario HU-021/HU-022.
///
/// Es un objeto de valor inmutable: separa lo que el formulario captura de cómo
/// se transmite al servidor. No contiene la contraseña ni el correo de acceso,
/// porque ambos pertenecen a Supabase Auth y solo se usan al crear la cuenta.
class UsuarioBorrador {
  final String nombres, apellidos, nombreUsuario, cargo, rol;
  final List<String> areas;
  final String colegioCodigo, numeroColegiatura, especialidadCodigo;
  final bool puedeGestionarKits;

  /// Construye el borrador; los textos se limpian en [toJson] antes de enviarse.
  const UsuarioBorrador({
    required this.nombres,
    required this.apellidos,
    required this.nombreUsuario,
    required this.cargo,
    required this.rol,
    required this.areas,
    this.colegioCodigo = '',
    this.numeroColegiatura = '',
    this.especialidadCodigo = '',
    this.puedeGestionarKits = false,
  });

  /// Convierte el borrador al JSON que esperan las RPC `administrar_usuario_hu020`
  /// y `registrar_perfil_usuario_hu021`. El servidor vuelve a validar cada campo.
  ///
  /// Minimización: la entidad `UsuarioAdministrativo` tiene más campos que la
  /// petición. Solo se envía lo que el servidor guarda o valida:
  ///
  /// | Campo de la entidad                      | Se envía | Motivo |
  /// |------------------------------------------|----------|--------|
  /// | id                                       | Aparte (`p_id`) | Identifica el perfil a editar; no va en el perfil |
  /// | nombres, apellidos                       | Sí | El servidor los guarda en el perfil |
  /// | usuario (nombre_usuario)                 | Sí | Servidor valida unicidad y lo guarda |
  /// | cargo                                    | Sí | Define si aplica gestión de kits |
  /// | rol                                      | Sí | El servidor asigna permisos |
  /// | areas                                    | Sí | Servidor las valida y asigna |
  /// | puedeGestionarKits                       | Sí | Permiso que el servidor persiste |
  /// | colegioCodigo, numeroColegiatura, especialidadCodigo | Sí | Datos profesionales que el servidor valida |
  /// | correo                                   | No (solo al crear, fuera del perfil) | Pertenece a Auth; no se edita aquí |
  /// | nombreAnterior                           | No | Dato heredado; el servidor no lo usa |
  /// | activo                                   | No | Se cambia por una acción aparte (`ESTADO`) |
  /// | creado, actualizado                      | No | Los fija el servidor |
  /// | colegioNombre, especialidadNombre        | No | Solo para mostrar; el servidor los deriva del código |
  ///
  /// La petición no lleva coordenadas.
  Map<String, dynamic> toJson() => {
    'nombres': nombres.trim(),
    'apellidos': apellidos.trim(),
    'nombre_usuario': nombreUsuario.trim(),
    'cargo': cargo.trim(),
    'rol': rol,
    'areas': areas,
    'puede_gestionar_kits': puedeGestionarKits,
    'colegio_codigo': colegioCodigo.isEmpty ? null : colegioCodigo,
    'numero_colegiatura': numeroColegiatura.trim().isEmpty
        ? null
        : numeroColegiatura.trim(),
    'especialidad_codigo': especialidadCodigo.isEmpty
        ? null
        : especialidadCodigo,
  };
}
