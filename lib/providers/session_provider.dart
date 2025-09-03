import 'package:flutter/material.dart';

class SessionProvider with ChangeNotifier {
  String? activeSchoolId;
  String? activeRole;

  void setActiveSession(String schoolId, String role) {
    activeSchoolId = schoolId;
    activeRole = role;
    notifyListeners();
  }

  void clearSession() {
    activeSchoolId = null;
    activeRole = null;
    notifyListeners();
  }
}
