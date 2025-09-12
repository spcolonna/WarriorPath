// lib/services/remote_config_service.dart

import 'package:firebase_remote_config/firebase_remote_config.dart';

class RemoteConfigService {
  final FirebaseRemoteConfig _remoteConfig;

  static RemoteConfigService? _instance;

  RemoteConfigService._(this._remoteConfig);

  static RemoteConfigService get instance {
    if (_instance == null) {
      throw Exception('RemoteConfigService no ha sido inicializado. Llama a getInstance() primero en tu main.dart');
    }
    return _instance!;
  }

  static Future<RemoteConfigService> getInstance() async {
    if (_instance == null) {
      final remoteConfig = FirebaseRemoteConfig.instance;
      await remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(minutes: 1),
        minimumFetchInterval: Duration.zero,
      ));

      // --- CAMBIO: AÑADIMOS EL VALOR POR DEFECTO PARA EL BANNER ---
      await remoteConfig.setDefaults(const {
        "online_payments_enabled": false,
        "show_banner_ad": false, // Apagado por defecto
      });
      // --- FIN DEL CAMBIO ---

      _instance = RemoteConfigService._(remoteConfig);
    }
    return _instance!;
  }

  // Getter específico que ya tenías
  bool get onlinePaymentsEnabled => _remoteConfig.getBool('online_payments_enabled');

  // --- CAMBIO: AÑADIMOS EL MÉTODO GENÉRICO QUE FALTA ---
  /// Obtiene un valor booleano de Remote Config usando una clave (key).
  bool getBool(String key) {
    return _remoteConfig.getBool(key);
  }
  // --- FIN DEL CAMBIO ---


  Future<void> fetchAndActivate() async {
    try {
      await _remoteConfig.fetchAndActivate();
    } catch (e) {
      print('Error al cargar Remote Config: $e');
    }
  }
}
