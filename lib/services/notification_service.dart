import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:io';

import 'local_notification_service.dart';
import 'notification_router.dart';

/// Permite navegar desde fuera del árbol de widgets, que es lo que hace falta
/// cuando el usuario toca una notificación y hay que llevarlo a una pantalla.
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

class NotificationService with WidgetsBindingObserver {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  bool _isInitialized = false;

  /// Evita que se solapen varios ciclos de registro (cada uno espera hasta 10s
  /// por el token de APNS).
  bool _registrationInProgress = false;

  /// El simulador de iOS no tiene APNs: pedirle un token siempre devuelve null.
  /// Se detecta por una variable de entorno que sólo existe en el simulador,
  /// así no hace falta sumar una dependencia para averiguarlo.
  static bool get isIosSimulator =>
      Platform.isIOS &&
      Platform.environment.containsKey('SIMULATOR_DEVICE_NAME');

  /// Si el registro falló al arrancar (típico en iOS cuando APNS todavía no
  /// respondió), se reintenta cada vez que la app vuelve del segundo plano.
  /// Para entonces suele estar todo listo.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ensureTokenRegistered();
    }
  }

  Future<void> initialize() async {
    // Evitamos inicializarlo múltiples veces
    if (_isInitialized) return;

    // 1. Pedir permisos al usuario (para iOS y Android 13+)
    await _fcm.requestPermission();

    // 2. Obtener el token y guardarlo para el usuario actual (si existe)
    // Esto cubre el caso de que el usuario ya tenga la sesión iniciada al abrir la app.
    await ensureTokenRegistered();

    // 3. Configurar listeners para que todo sea automático
    _setupListeners();
    _setupMessageHandlers();
    WidgetsBinding.instance.addObserver(this);

    _isInitialized = true;
    if (kDebugMode) {
      print("Servicio de Notificaciones Inicializado.");
    }
  }

  /// Se asegura de que el dispositivo quede registrado para recibir push.
  ///
  /// Antes esto sólo se intentaba una vez al arrancar: si el token de APNS no
  /// estaba listo, o no había red, el usuario se quedaba SIN NOTIFICACIONES
  /// para siempre y sin ninguna señal de que algo había fallado.
  ///
  /// Devuelve true si el token quedó guardado.
  Future<bool> ensureTokenRegistered() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    // El simulador de iOS no puede registrarse con APNs: no tiene sentido
    // reintentar 10 segundos para fracasar siempre.
    if (isIosSimulator) {
      lastTokenError = 'El simulador de iOS no puede recibir notificaciones '
          'push. Probá en un dispositivo físico.';
      return false;
    }

    // Sin este guard, cada vuelta a primer plano lanza otro ciclo de reintentos
    // en paralelo y se pisan entre sí.
    if (_registrationInProgress) return false;
    _registrationInProgress = true;

    try {
      final settings = await _fcm.getNotificationSettings();
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        if (kDebugMode) {
          print("Notificaciones denegadas por el usuario.");
        }
        return false;
      }

      final token = await _getFcmTokenSafely();
      if (token == null) return false;

      await _saveTokenToDatabase(token, user.uid);
      debugPrint('[PUSH] token guardado para ${user.uid}');
      return true;
    } catch (e) {
      lastTokenError = e.toString();
      debugPrint('[PUSH] no se pudo registrar el token: $e');
      return false;
    } finally {
      _registrationInProgress = false;
    }
  }

  /// Estado de las notificaciones en este dispositivo, para poder mostrárselo
  /// al usuario en vez de que falle en silencio.
  Future<NotificationDiagnostics> diagnose() async {
    final user = FirebaseAuth.instance.currentUser;
    final settings = await _fcm.getNotificationSettings();

    final permissionGranted =
        settings.authorizationStatus == AuthorizationStatus.authorized ||
            settings.authorizationStatus == AuthorizationStatus.provisional;

    if (user == null) {
      return NotificationDiagnostics(
        permissionGranted: permissionGranted,
        deviceRegistered: false,
      );
    }

    if (isIosSimulator) {
      return NotificationDiagnostics(
        permissionGranted: permissionGranted,
        deviceRegistered: false,
        errorDetail: 'El simulador de iOS no puede recibir push. '
            'Probá en un iPhone real.',
      );
    }

    bool registered = false;
    String? error;
    try {
      // Lo que realmente determina si el servidor puede notificar es que haya
      // tokens guardados en el perfil. Se consulta ESO primero.
      //
      // Antes se arrancaba pidiendo el token a APNs, y si esa lectura fallaba
      // momentáneamente se concluía "no registrado" aunque las notificaciones
      // estuvieran llegando perfectamente: un falso negativo que asustaba al
      // usuario sin motivo.
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get(const GetOptions(source: Source.server));
      final tokens = (doc.data()?['fcmTokens'] as List?) ?? [];

      if (tokens.isEmpty) {
        error = lastTokenError ?? 'Este dispositivo todavía no se registró.';
      } else {
        // Hay tokens: el usuario recibe notificaciones. Queda confirmar que uno
        // sea de ESTE dispositivo, sin el ciclo largo de reintentos.
        String? current;
        try {
          current = await _fcm.getToken().timeout(const Duration(seconds: 5));
        } catch (_) {
          current = null;
        }

        if (current == null) {
          // No se pudo leer el token local, pero el perfil tiene tokens y el
          // permiso está dado: no hay motivo para alarmar.
          registered = true;
        } else if (tokens.contains(current)) {
          registered = true;
        } else {
          // El perfil tiene tokens de otros dispositivos pero no de éste:
          // se intenta registrarlo en el momento, sin molestar al usuario.
          registered = await ensureTokenRegistered();
          if (!registered) {
            error = lastTokenError ?? 'No se pudo registrar este dispositivo.';
          }
        }
      }
    } catch (e) {
      error = e.toString();
    }

    return NotificationDiagnostics(
      permissionGranted: permissionGranted,
      deviceRegistered: registered,
      errorDetail: error,
    );
  }

  /// Recepción de mensajes. Sin esto, en Android no se ve nada con la app
  /// abierta y tocar una notificación no lleva a ninguna parte.
  void _setupMessageHandlers() {
    // App abierta: Android no muestra el push solo, hay que dibujarlo.
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      if (notification != null) {
        LocalNotificationService.showForegroundMessage(
          title: notification.title ?? '',
          body: notification.body ?? '',
        );
      }
    });

    // App en segundo plano y el usuario toca la notificación.
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageTap);

    // App cerrada del todo: el mensaje que la abrió.
    _fcm.getInitialMessage().then((message) {
      if (message != null) {
        // Se espera a que el árbol de navegación exista antes de rutear.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _handleMessageTap(message);
        });
      }
    });
  }

  void _handleMessageTap(RemoteMessage message) {
    NotificationRouter.handle(appNavigatorKey, message.data);
  }

  void _setupListeners() {
    // Listener 1: Si el token cambia, lo actualizamos.
    _fcm.onTokenRefresh.listen((token) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        _saveTokenToDatabase(token, user.uid);
      }
    });

    // Listener 2: Si el estado de autenticación cambia (login/logout).
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        _lastKnownUid = user.uid;
        // El usuario acaba de iniciar sesión. Obtenemos el token y lo guardamos.
        _getFcmTokenSafely().then((token) {
          if (token != null) {
            _saveTokenToDatabase(token, user.uid);
          }
        });
      } else if (_lastKnownUid != null) {
        // Logout: hay que desasociar el token de este dispositivo. Si no, el
        // que use el teléfono después sigue recibiendo los push del anterior.
        final previousUid = _lastKnownUid!;
        _lastKnownUid = null;
        _removeTokenFromDatabase(previousUid);
      }
    });
  }

  /// uid de la última sesión, para saber a quién desasociar el token al salir.
  String? _lastKnownUid;

  Future<void> _removeTokenFromDatabase(String userId) async {
    try {
      final token = await _fcm.getToken();
      if (token == null) return;
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'fcmTokens': FieldValue.arrayRemove([token]),
      });
    } catch (e) {
      if (kDebugMode) {
        print("Error quitando token en logout: $e");
      }
    }
  }

  /// Último motivo por el que no se pudo obtener el token, para poder
  /// mostrarlo en vez de dejar al usuario adivinando.
  String? lastTokenError;

  /// En iOS el token APNS puede no estar listo al arrancar la app. Reintenta
  /// hasta 5 veces con 2 segundos de espera antes de rendirse.
  Future<String?> _getFcmTokenSafely() async {
    lastTokenError = null;

    if (Platform.isIOS) {
      final settings = await _fcm.getNotificationSettings();
      debugPrint('[PUSH] permiso: ${settings.authorizationStatus}');

      String? apns;
      for (int i = 0; i < 5; i++) {
        try {
          apns = await _fcm.getAPNSToken();
          debugPrint('[PUSH] intento ${i + 1}/5 APNS: '
              '${apns == null ? "null" : "OK (${apns.length} chars)"}');
          if (apns == null) {
            await Future.delayed(const Duration(seconds: 2));
            continue;
          }
          break;
        } catch (e) {
          lastTokenError = 'APNS: $e';
          debugPrint('[PUSH] error APNS intento ${i + 1}: $e');
          await Future.delayed(const Duration(seconds: 2));
        }
      }

      if (apns == null) {
        // Sin token de APNS no hay nada que hacer: o el dispositivo no pudo
        // registrarse con Apple, o falta la capability de Push Notifications.
        lastTokenError ??= 'No se obtuvo el token de APNS (¿permiso o '
            'capability de Push Notifications?)';
        debugPrint('[PUSH] FALLO: $lastTokenError');
        return null;
      }

      try {
        // Ojo: esto NO es local. Canjea el token de APNS contra los servidores
        // de FCM, así que falla si el proyecto de Firebase no tiene cargada la
        // clave de APNS del entorno correspondiente (sandbox en debug,
        // producción en TestFlight/App Store).
        final token = await _fcm.getToken();
        debugPrint('[PUSH] token FCM: '
            '${token == null ? "null" : "OK ${token.substring(0, 20)}..."}');
        return token;
      } catch (e) {
        lastTokenError = 'FCM: $e';
        debugPrint('[PUSH] error obteniendo token FCM: $e');
        return null;
      }
    }

    try {
      final token = await _fcm.getToken();
      debugPrint('[PUSH] token FCM (Android): '
          '${token == null ? "null" : "OK"}');
      return token;
    } catch (e) {
      lastTokenError = 'FCM: $e';
      debugPrint('[PUSH] error obteniendo token FCM: $e');
      return null;
    }
  }

  Future<void> _saveTokenToDatabase(String token, String userId) async {
    try {
      // Usamos tu lógica de arrayUnion, que es excelente.
      await FirebaseFirestore.instance.collection('users').doc(userId).set({
        'fcmTokens': FieldValue.arrayUnion([token]),
        'lastTokenUpdate': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (kDebugMode) {
        print("FCM Token guardado/actualizado para el usuario: $userId");
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error guardando token: $e");
      }
    }
  }
}

/// Por qué un usuario puede no estar recibiendo notificaciones.
///
/// Se distinguen los dos motivos porque la solución es distinta: si falta el
/// permiso hay que ir a los ajustes del sistema; si falta el registro alcanza
/// con reintentar desde la app.
class NotificationDiagnostics {
  /// El usuario aceptó recibir notificaciones en este dispositivo.
  final bool permissionGranted;

  /// El token de este dispositivo está guardado en el perfil del usuario.
  /// Sin esto el servidor no tiene a dónde mandar el push.
  final bool deviceRegistered;

  /// Motivo técnico del fallo, para poder diagnosticarlo sin adivinar.
  final String? errorDetail;

  const NotificationDiagnostics({
    required this.permissionGranted,
    required this.deviceRegistered,
    this.errorDetail,
  });

  bool get isWorking => permissionGranted && deviceRegistered;
}
