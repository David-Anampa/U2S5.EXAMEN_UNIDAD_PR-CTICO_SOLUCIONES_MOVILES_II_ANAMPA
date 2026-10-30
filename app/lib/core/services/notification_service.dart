import '../logging/registro_app.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Manejador de notificaciones push en segundo plano (requerido a nivel superior por FCM)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  RegistroApp.log('📩 [FCM Background] Mensaje recibido: ${message.messageId}');
  RegistroApp.log('   Título: ${message.notification?.title}');
  RegistroApp.log('   Cuerpo: ${message.notification?.body}');
}

/// Servicio centralizado de Notificaciones Push con Firebase Cloud Messaging (FCM).
///
/// Firebase se utiliza ÚNICAMENTE como canal de mensajería y alertas en tiempo real,
/// mientras que los datos y perfiles se gestionan en Supabase.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  /// Bandera para habilitar o diferir las notificaciones push de Firebase (FCM).
  /// Actualmente desactivada (false) ya que la base de datos y autenticación están
  /// 100% en Supabase, y el módulo de notificaciones push se activará en una fase posterior.
  static const bool enablePushNotifications = false;

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  bool _initialized = false;
  bool get isInitialized => _initialized;

  /// Inicializa Firebase Cloud Messaging y configura los receptores de eventos
  Future<void> initialize() async {
    if (!enablePushNotifications) {
      RegistroApp.log('ℹ️ [NotificationService] Firebase FCM pospuesto para una fase posterior. Supabase gestiona BD y Auth.');
      return;
    }
    if (_initialized) return;

    try {
      final messaging = FirebaseMessaging.instance;

      // 1. Solicitar permisos de notificación (Android 13+ e iOS)
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      RegistroApp.log('🔔 [FCM] Permisos de notificación: ${settings.authorizationStatus}');

      // 2. Obtener el token de FCM para este dispositivo
      _fcmToken = await messaging.getToken();
      RegistroApp.log('🔑 [FCM Token] obtenido');

      // 3. Suscribirse a cambios o renovaciones del token
      messaging.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        RegistroApp.log('🔄 [FCM Token] renovado');
        syncTokenWithSupabase(newToken);
      });

      // 4. Configurar receptor de mensajes en segundo plano
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // 5. Escuchar notificaciones en primer plano (foreground)
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        RegistroApp.log('🔔 [FCM Foreground] Notificación recibida:');
        RegistroApp.log('   Título: ${message.notification?.title}');
        RegistroApp.log('   Cuerpo: ${message.notification?.body}');
        RegistroApp.log('   Data: ${message.data}');
      });

      // 6. Escuchar cuando el usuario toca una notificación
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        RegistroApp.log('👆 [FCM Click] Notificación abierta por el usuario: ${message.data}');
      });

      _initialized = true;
    } catch (e) {
      RegistroApp.log('⚠️ [NotificationService] Error al inicializar FCM: $e');
    }
  }

  /// Vincula el token de FCM del dispositivo con el perfil del usuario en Supabase
  Future<void> syncTokenWithSupabase([String? token]) async {
    if (!enablePushNotifications) return;
    final activeToken = token ?? _fcmToken;
    if (activeToken == null || activeToken.isEmpty) return;

    try {
      final client = Supabase.instance.client;
      final currentUserId = client.auth.currentUser?.id;

      if (currentUserId != null) {
        await client.from('profiles').update({
          'fcm_token': activeToken,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        }).eq('id', currentUserId);

        RegistroApp.log('✅ [NotificationService] FCM token sincronizado con Supabase');
      }
    } catch (e) {
      RegistroApp.log('⚠️ [NotificationService] No se pudo sincronizar el FCM token con Supabase: $e');
    }
  }
}
