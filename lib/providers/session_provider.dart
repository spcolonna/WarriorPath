import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SessionProvider with ChangeNotifier {
  static const _kSchoolId  = 'session_school_id';
  static const _kRole      = 'session_role';
  static const _kProfileId = 'session_profile_id';
  static const _kAuthUid   = 'session_auth_uid';

  String? activeSchoolId;
  String? activeRole;
  String? activeProfileId;

  /// Establece la sesión completa y la persiste localmente.
  ///
  /// [authUid] es el uid de Firebase Auth realmente logueado al momento de
  /// guardar (no necesariamente igual a [profileId]: un tutor puede tener
  /// activo el perfil de un hijo). Se guarda para que, en el próximo cold
  /// start, [AppSplashScreen] pueda validar que la sesión persistida sigue
  /// perteneciendo al usuario autenticado actual antes de restaurarla.
  void setFullActiveSession(String schoolId, String role, String profileId, {required String authUid}) {
    activeSchoolId  = schoolId;
    activeRole      = role;
    activeProfileId = profileId;
    notifyListeners();
    _persist(schoolId, role, profileId, authUid);
  }

  /// Cambia solo el perfil activo (ej: padre seleccionando a un hijo).
  void setActiveProfileId(String? profileId) {
    activeProfileId = profileId;
    notifyListeners();
  }

  /// Borra la sesión en memoria y en disco.
  void clearSession() {
    activeSchoolId  = null;
    activeRole      = null;
    activeProfileId = null;
    notifyListeners();
    _clear();
  }

  // ── Persistencia ─────────────────────────────────────────────────────────────

  static Future<void> _persist(
      String schoolId, String role, String profileId, String authUid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kSchoolId,  schoolId);
    await prefs.setString(_kRole,      role);
    await prefs.setString(_kProfileId, profileId);
    await prefs.setString(_kAuthUid,   authUid);
  }

  static Future<void> _clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kSchoolId);
    await prefs.remove(_kRole);
    await prefs.remove(_kProfileId);
    await prefs.remove(_kAuthUid);
  }

  /// Devuelve los datos de sesión guardados, o null si no hay ninguno.
  static Future<SavedSession?> loadSaved() async {
    final prefs     = await SharedPreferences.getInstance();
    final schoolId  = prefs.getString(_kSchoolId);
    final role      = prefs.getString(_kRole);
    final profileId = prefs.getString(_kProfileId);
    final authUid   = prefs.getString(_kAuthUid);
    if (schoolId == null || role == null || profileId == null || authUid == null) return null;
    return SavedSession(schoolId: schoolId, role: role, profileId: profileId, authUid: authUid);
  }
}

class SavedSession {
  final String schoolId;
  final String role;
  final String profileId;
  /// Uid de Firebase Auth que estaba logueado cuando se guardó esta sesión.
  /// Debe validarse contra el usuario actual antes de restaurarla.
  final String authUid;
  const SavedSession(
      {required this.schoolId,
      required this.role,
      required this.profileId,
      required this.authUid});
}
