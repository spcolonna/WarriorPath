import 'package:flutter/material.dart';

class MartialArtTheme {
  final String name;
  final Color primaryColor;
  final Color accentColor;
  // Puedes añadir más colores o propiedades según necesites
  final String logoPath; // Por si cada arte marcial tiene un logo específico

  const MartialArtTheme({
    required this.name,
    required this.primaryColor,
    required this.accentColor,
    this.logoPath = 'assets/logo/Logo.png', // Por defecto el logo general
  });

  static const MartialArtTheme kungFu = MartialArtTheme(
    name: 'Kung Fu',
    primaryColor: Color(0xFFE65100), // Naranja Tradicional Shaolin
    accentColor: Color(0xFFFFA726),
    // logoPath: 'assets/logos_martial_arts/kungfu_logo.png', // Si tuvieras un logo específico
  );

  static final MartialArtTheme taiChi = MartialArtTheme(
    name: 'Tai Chi',
    primaryColor: const Color(0xFF4CAF50), // Un verde sereno
    accentColor: const Color(0xFF81C784),
  );

  static const MartialArtTheme karate = MartialArtTheme(
    name: 'Karate',
    primaryColor: Color(0xFF0D47A1), // Azul profundo
    accentColor: Color(0xFF42A5F5),
    // logoPath: 'assets/logos_martial_arts/karate_logo.png',
  );

  static const MartialArtTheme taekwondo = MartialArtTheme(
    name: 'Taekwondo',
    primaryColor: Color(0xFFD32F2F), // Rojo fuerte
    accentColor: Color(0xFFEF5350),
    // logoPath: 'assets/logos_martial_arts/taekwondo_logo.png',
  );

  static const MartialArtTheme jiuJitsu = MartialArtTheme(
    name: 'Jiu Jitsu',
    primaryColor: Color(0xFF4CAF50), // Verde
    accentColor: Color(0xFF81C784),
    // logoPath: 'assets/logos_martial_arts/jiujitsu_logo.png',
  );

  static List<MartialArtTheme> get allThemes => [
    kungFu,
    taiChi,
    karate,
    taekwondo,
    jiuJitsu,
  ];
}
