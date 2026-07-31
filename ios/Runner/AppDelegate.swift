import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Registro explícito con APNs. Normalmente lo dispara firebase_messaging al
    // conceder el permiso, pero pedirlo acá también es inofensivo (iOS ignora
    // las llamadas repetidas) y descarta que el plugin no lo esté haciendo.
    application.registerForRemoteNotifications()

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // Los dos callbacks siguientes son de diagnóstico: sin ellos, cuando iOS se
  // niega a registrar el dispositivo el fallo es completamente silencioso y del
  // lado de Dart sólo se ve un token nulo, sin ninguna pista del motivo.
  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    let hex = deviceToken.map { String(format: "%02x", $0) }.joined()
    // Se loguea por las dos vías: NSLog va a la consola del sistema (Console.app
    // / Xcode) y print a stdout, que es lo que muestra `flutter run`. Con una
    // sola de las dos el mensaje se pierde según cómo se esté ejecutando.
    let msg = "[PUSH-NATIVO] APNs OK, device token: \(hex.prefix(16))... (\(hex.count) chars)"
    NSLog(msg)
    print(msg)
    super.application(
      application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }

  override func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    let ns = error as NSError
    let msg = "[PUSH-NATIVO] APNs FALLÓ: \(error.localizedDescription) " +
      "| domain=\(ns.domain) code=\(ns.code)"
    NSLog(msg)
    print(msg)
    super.application(
      application, didFailToRegisterForRemoteNotificationsWithError: error)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
