import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SessionProvider with ChangeNotifier {
  static const _kSchoolId  = 'session_school_id';
  static const _kRole      = 'session_role';
  static const _kProfileId = 'session_profile_id';

  String? activeSchoolId;
  String? activeRole;
  String? activeProfileId;

  /// Establece la sesión completa y la persiste localmente.
  void setFullActiveSession(String schoolId, String role, String profileId) {
    activeSchoolId  = schoolId;
    activeRole      = role;
    activeProfileId = profileId;
    notifyListeners();
    _persist(schoolId, role, profileId);
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
      String schoolId, String role, String profileId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kSchoolId,  schoolId);
    await prefs.setString(_kRole,      role);
    await prefs.setString(_kProfileId, profileId);
  }

  static Future<void> _clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kSchoolId);
    await prefs.remove(_kRole);
    await prefs.remove(_kProfileId);
  }

  /// Devuelve los datos de sesión guardados, o null si no hay ninguno.
  static Future<SavedSession?> loadSaved() async {
    final prefs     = await SharedPreferences.getInstance();
    final schoolId  = prefs.getString(_kSchoolId);
    final role      = prefs.getString(_kRole);
    final profileId = prefs.getString(_kProfileId);
    if (schoolId == null || role == null || profileId == null) return null;
    return SavedSession(schoolId: schoolId, role: role, profileId: profileId);
  }
}

class SavedSession {
  final String schoolId;
  final String role;
  final String profileId;
  const SavedSession(
      {required this.schoolId,
      required this.role,
      required this.profileId});
}
