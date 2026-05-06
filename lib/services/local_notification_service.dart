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
