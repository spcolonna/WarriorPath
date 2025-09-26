import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:warrior_path/theme/martial_art_themes.dart';

class ThemeProvider with ChangeNotifier {
  MartialArtTheme _currentTheme = MartialArtTheme.karate;

  MartialArtTheme get theme => _currentTheme;

  Future<void> loadThemeFromSchool(String schoolId) async {
    try {
      final primaryDisciplineSnapshot = await FirebaseFirestore.instance
          .collection('schools').doc(schoolId)
          .collection('disciplines')
          .where('isPrimary', isEqualTo: true)
          .limit(1)
          .get();

      if (primaryDisciplineSnapshot.docs.isNotEmpty) {
        final disciplineDoc = primaryDisciplineSnapshot.docs.first;
        final disciplineName = disciplineDoc.data()['name'] as String?;

        if (disciplineName != null) {
          // 2. Buscamos en nuestra lista de temas el que coincida con ese nombre.
          final foundTheme = MartialArtTheme.allThemes.firstWhere(
                (theme) => theme.name == disciplineName,
            orElse: () => MartialArtTheme.karate, // Fallback por si no lo encuentra
          );
          _currentTheme = foundTheme;
        }
      }

      notifyListeners();

    } catch (e) {
      print("Error al cargar el tema: $e");
    }
  }
}
