import 'package:flutter/material.dart';

class SessionProvider with ChangeNotifier {
  String? activeSchoolId;
  String? activeRole;

  // --- CAMBIO: Añadimos el ID del perfil que se está gestionando ---
  // Puede ser el del propio usuario logueado, o el de un hijo.
  String? activeProfileId;

  /// Establece la sesión completa, se usa en el login normal.
  void setFullActiveSession(String schoolId, String role, String profileId) {
    activeSchoolId = schoolId;
    activeRole = role;
    activeProfileId = profileId;
    notifyListeners();
  }

  /// Cambia solo el perfil activo (ej: un padre seleccionando a un hijo).
  void setActiveProfileId(String profileId) {
    activeProfileId = profileId;
    // No borramos la escuela o el rol, porque el siguiente paso será elegir uno para este nuevo perfil
    notifyListeners();
  }

  void clearSession() {
    activeSchoolId = null;
    activeRole = null;
    activeProfileId = null; // Limpiamos también el perfil activo
    notifyListeners();
  }
}
