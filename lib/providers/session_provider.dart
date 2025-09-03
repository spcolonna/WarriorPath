import 'package:flutter/material.dart';

// Este provider no necesita notificar cambios por ahora,
// ya que la navegación se encargará de reconstruir las vistas.
// Podríamos usar ChangeNotifier si en el futuro queremos cambiar de escuela sin navegar.
class SessionProvider {
  String? activeSchoolId;
  String? activeRole;

  void setActiveSession(String schoolId, String role) {
    activeSchoolId = schoolId;
    activeRole = role;
    // En una app más compleja, aquí llamaríamos a notifyListeners()
  }

  void clearSession() {
    activeSchoolId = null;
    activeRole = null;
  }
}
