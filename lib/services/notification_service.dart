import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  bool _isInitialized = false;

  Future<void> initialize() async {
    // Evitamos inicializarlo múltiples veces
    if (_isInitialized) return;

    // 1. Pedir permisos al usuario (para iOS y Android 13+)
    await _fcm.requestPermission();

    // 2. Obtener el token y guardarlo para el usuario actual (si existe)
    // Esto cubre el caso de que el usuario ya tenga la sesión iniciada al abrir la app.
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final token = await _fcm.getToken();
      if (token != null) {
        await _saveTokenToDatabase(token, user.uid);
      }
    }

    // 3. Configurar listeners para que todo sea automático
    _setupListeners();

    _isInitialized = true;
    if (kDebugMode) {
      print("Servicio de Notificaciones Inicializado.");
    }
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
        // El usuario acaba de iniciar sesión. Obtenemos el token y lo guardamos.
        _fcm.getToken().then((token) {
          if (token != null) {
            _saveTokenToDatabase(token, user.uid);
          }
        });
      }
      // No hacemos nada en logout. El token sigue siendo válido para el dispositivo
      // y se asociará al siguiente usuario que inicie sesión.
    });
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
