import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:warrior_path/theme/martial_art_themes.dart';

class ThemeProvider with ChangeNotifier {
  MartialArtTheme _currentTheme = MartialArtTheme.kungFu; // Un tema por defecto

  MartialArtTheme get theme => _currentTheme;

  Future<void> loadThemeFromSchool(String schoolId) async {
    try {
      final schoolDoc = await FirebaseFirestore.instance.collection('schools').doc(schoolId).get();
      final themeData = schoolDoc.data()?['theme'] as Map<String, dynamic>?;

      if (themeData != null) {
        final primaryColor = Color(int.parse(themeData['primaryColor'], radix: 16));
        final accentColor = Color(int.parse(themeData['accentColor'], radix: 16));
        final martialArtName = schoolDoc.data()?['martialArt'] ?? 'Custom';

        _currentTheme = MartialArtTheme(
          name: martialArtName,
          primaryColor: primaryColor,
          accentColor: accentColor,
        );
        notifyListeners(); // Notifica a los widgets que el tema ha cambiado
      }
    } catch (e) {
      print("Error al cargar el tema: $e");
      // Mantiene el tema por defecto si hay un error
    }
  }
}
