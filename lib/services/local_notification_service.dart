import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:warrior_path/services/achievement_engine.dart';

class LocalNotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );
    _initialized = true;
  }

  /// Muestra una notificación recibida con la app en primer plano.
  ///
  /// Android no despliega nada por sí solo cuando la app está abierta, así que
  /// sin esto los push que llegan mientras el usuario usa la app pasan
  /// desapercibidos.
  static Future<void> showForegroundMessage({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_initialized) return;
    const androidDetails = AndroidNotificationDetails(
      'general_channel',
      'General',
      channelDescription: 'Avisos de tu escuela: pagos, clases y progreso',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      const NotificationDetails(android: androidDetails, iOS: iosDetails),
      payload: payload,
    );
  }

  static Future<void> showAchievementUnlocked(
      AchievementStatus status) async {
    if (!_initialized) return;
    const androidDetails = AndroidNotificationDetails(
      'achievements_channel',
      'Logros',
      channelDescription: 'Notificaciones cuando desbloqueas un logro',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: false,
      presentSound: true,
    );
    await _plugin.show(
      status.def.id.hashCode.abs(),
      '🏆 ¡Logro desbloqueado!',
      status.def.title,
      const NotificationDetails(android: androidDetails, iOS: iosDetails),
    );
  }
}
