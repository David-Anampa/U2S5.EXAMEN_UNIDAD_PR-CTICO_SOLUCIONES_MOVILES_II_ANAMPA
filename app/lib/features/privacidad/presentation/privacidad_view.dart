import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/diseno_adaptable.dart';
import '../data/consentimiento_repository.dart';
import 'consentimiento_viewmodel.dart';

/// Pantalla de consentimiento. Se muestra la primera vez que se abre la app y
/// se reabre desde «Privacidad» mostrando la decisión guardada.
class PrivacidadView extends StatefulWidget {
  const PrivacidadView({super.key});

  @override
  State<PrivacidadView> createState() => _PrivacidadViewState();
}

class _PrivacidadViewState extends State<PrivacidadView> {
  late bool _analitica;
  late bool _promocionales;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    // Sin decisión previa, ambos interruptores empiezan apagados.
    final previa = context.read<ConsentimientoViewModel>().decision;
    _analitica = previa?.analitica ?? false;
    _promocionales = previa?.promocionales ?? false;
  }

  Future<void> _guardar({bool? analitica, bool? promocionales}) async {
    if (_guardando) return;
    setState(() => _guardando = true);
    final vm = context.read<ConsentimientoViewModel>();
    final primeraVez = !vm.decidido;
    await vm.guardar(
      analitica: analitica ?? _analitica,
      promocionales: promocionales ?? _promocionales,
    );
    if (!mounted) return;
    setState(() => _guardando = false);
    if (context.canPop()) {
      context.pop();
    } else if (primeraVez) {
      context.go('/login');
    }
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      const SnackBar(content: Text('Tu decisión de privacidad fue guardada.')),
    );
  }

  String _fecha(DateTime f) {
    String d(int n) => n.toString().padLeft(2, '0');
    return '${d(f.day)}/${d(f.month)}/${f.year} ${d(f.hour)}:${d(f.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final guardada = context.watch<ConsentimientoViewModel>().decision;
    // Mismo estilo para aceptar y rechazar: igual peso visual.
    final estiloBoton = OutlinedButton.styleFrom(
      minimumSize: const Size.fromHeight(52),
      foregroundColor: AppColors.primary,
      side: const BorderSide(color: AppColors.primary, width: 1.5),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Privacidad'),
        automaticallyImplyLeading: context.canPop(),
      ),
      body: SafeArea(
        child: ContenidoAdaptable(
          child: ListView(
            children: [
              const Text(
                'Tú decides qué datos se usan',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'SITRA-Luz solo usa los datos necesarios para operar. Los '
                'siguientes usos son opcionales y están desactivados por '
                'defecto. Puedes cambiarlos cuando quieras desde «Privacidad».',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              _TarjetaConsentimiento(
                titulo: 'Analítica de uso',
                descripcion:
                    'Permite registrar estadísticas anónimas de uso (pantallas '
                    'visitadas) para mejorar la app. No incluye datos clínicos.',
                valor: _analitica,
                onChanged: (v) => setState(() => _analitica = v),
              ),
              const SizedBox(height: 12),
              _TarjetaConsentimiento(
                titulo: 'Notificaciones promocionales',
                descripcion:
                    'Permite enviarte avisos informativos no esenciales, como '
                    'novedades y capacitaciones. Las alertas operativas no '
                    'dependen de esta opción.',
                valor: _promocionales,
                onChanged: (v) => setState(() => _promocionales = v),
              ),
              const SizedBox(height: 16),
              if (guardada != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    'Decisión guardada · Política v${guardada.versionPolitica} '
                    '· ${_fecha(guardada.fecha)}',
                    key: const Key('privacidad_decision_guardada'),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    'Versión de la política: ${ConsentimientoRepository.versionVigente}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              AccionesAdaptables(
                acciones: [
                  OutlinedButton(
                    key: const Key('privacidad_rechazar'),
                    style: estiloBoton,
                    onPressed: _guardando
                        ? null
                        : () => _guardar(analitica: false, promocionales: false),
                    child: const Text('Rechazar todo'),
                  ),
                  OutlinedButton(
                    key: const Key('privacidad_guardar'),
                    style: estiloBoton,
                    onPressed: _guardando ? null : () => _guardar(),
                    child: const Text('Guardar selección'),
                  ),
                  OutlinedButton(
                    key: const Key('privacidad_aceptar'),
                    style: estiloBoton,
                    onPressed: _guardando
                        ? null
                        : () => _guardar(analitica: true, promocionales: true),
                    child: const Text('Aceptar todo'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TarjetaConsentimiento extends StatelessWidget {
  final String titulo;
  final String descripcion;
  final bool valor;
  final ValueChanged<bool> onChanged;

  const _TarjetaConsentimiento({
    required this.titulo,
    required this.descripcion,
    required this.valor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.surface,
      child: SwitchListTile(
        key: Key('switch_$titulo'),
        value: valor,
        onChanged: onChanged,
        title: Text(
          titulo,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(descripcion),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }
}
