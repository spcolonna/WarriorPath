// lib/services/remote_config_service.dart

import 'package:firebase_remote_config/firebase_remote_config.dart';

class RemoteConfigService {
  final FirebaseRemoteConfig _remoteConfig;

  static RemoteConfigService? _instance;

  RemoteConfigService._(this._remoteConfig);

  static RemoteConfigService get instance {
    if (_instance == null) {
      throw Exception(
        'RemoteConfigService no ha sido inicializado. Llama a getInstance() primero en tu main.dart',
      );
    }
    return _instance!;
  }

  static Future<RemoteConfigService> getInstance() async {
    if (_instance != null) return _instance!;

    final remoteConfig = FirebaseRemoteConfig.instance;
    // IMPORTANTE: asignar _instance ANTES de las llamadas async. Si alguna
    // falla en release (App Check/red/timeout), _instance igual queda seteado
    // y el acceso desde build() nunca lanza → sin crash de arranque.
    _instance = RemoteConfigService._(remoteConfig);

    try {
      await remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(minutes: 1),
          minimumFetchInterval: Duration.zero,
        ),
      );
      await remoteConfig.setDefaults(const {
        "online_payments_enabled": false,
        "show_banner_ad": false,
        "show_landing_screen": false,
      });
    } catch (e) {
      print('RemoteConfig setup error: $e');
    }

    return _instance!;
  }

  // Getter específico que ya tenías
  bool get onlinePaymentsEnabled =>
      _remoteConfig.getBool('online_payments_enabled');

  /// Obtiene un valor booleano de Remote Config usando una clave (key).
  bool getBool(String key) {
    return _remoteConfig.getBool(key);
  }

  /// Accessor estático SEGURO: nunca lanza. Si Remote Config no se inicializó
  /// o falla, devuelve [fallback]. Usar esto desde `build()` en vez de
  /// `RemoteConfigService.instance.getBool(...)` (que lanza si es null).
  static bool boolOf(String key, {bool fallback = false}) {
    try {
      return _instance?._remoteConfig.getBool(key) ?? fallback;
    } catch (_) {
      return fallback;
    }
  }

  Future<void> fetchAndActivate() async {
    try {
      await _remoteConfig.fetchAndActivate();
    } catch (e) {
      print('Error al cargar Remote Config: $e');
    }
  }
}
