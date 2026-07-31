import 'package:flutter/material.dart';

import '../screens/student/student_dashboard_screen.dart';
import '../screens/teacher_dashboard_screen.dart';

/// Lleva al usuario a la pantalla correcta cuando toca una notificación.
///
/// El backend manda un bloque `data` con `{type, schoolId, ...}` en cada push.
/// Antes los payloads eran sólo `notification`, así que tocar un aviso no hacía
/// absolutamente nada.
///
/// Se navega a la pestaña del dashboard que corresponde, en vez de a pantallas
/// sueltas, para que el botón "atrás" siga teniendo sentido.
class NotificationRouter {
  NotificationRouter._();

  // Pestañas del dashboard del maestro.
  static const int _teacherHome = 0;
  static const int _teacherStudents = 1;

  // Pestañas del dashboard del alumno.
  static const int _studentSchool = 0;
  static const int _studentProgress = 1;
  static const int _studentPayments = 3;

  static void handle(
    GlobalKey<NavigatorState> navigatorKey,
    Map<String, dynamic> data,
  ) {
    final type = data['type'] as String?;
    if (type == null) return;

    final navigator = navigatorKey.currentState;
    if (navigator == null) return;

    final destination = _destinationFor(type);
    if (destination == null) return;

    navigator.push(MaterialPageRoute(builder: (_) => destination));
  }

  static Widget? _destinationFor(String type) {
    switch (type) {
      // Para el maestro: alguien quiere entrar a la escuela.
      case 'join_request':
        return const TeacherDashboardScreen(
          initialTabIndex: _teacherStudents,
        );

      // Para el alumno: plata.
      case 'payment_due':
      case 'payment_registered':
        return const StudentDashboardScreen(
          initialTabIndex: _studentPayments,
        );

      // Para el alumno: su avance.
      case 'promotion':
      case 'techniques':
      case 'attendance':
        return const StudentDashboardScreen(
          initialTabIndex: _studentProgress,
        );

      // Para el alumno: novedades de la escuela.
      case 'application_accepted':
      case 'event_invite':
        return const StudentDashboardScreen(
          initialTabIndex: _studentSchool,
        );

      default:
        // Tipo desconocido (app vieja, notificación nueva): no hacer nada es
        // mejor que abrir una pantalla equivocada.
        return _unknown(type);
    }
  }

  static Widget? _unknown(String type) {
    debugPrint('NotificationRouter: tipo desconocido "$type", se ignora.');
    return null;
  }

  /// Índice de la pestaña Home del maestro, expuesto por si se necesita
  /// enrutar a la home desde otro lugar.
  static int get teacherHomeTab => _teacherHome;
}
