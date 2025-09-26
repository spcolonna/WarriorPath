import 'package:flutter/material.dart';

class MartialArtTheme {
  final String name;
  final Color primaryColor;
  final Color accentColor;
  final String icon;

  const MartialArtTheme({
    required this.name,
    required this.primaryColor,
    required this.accentColor,
    required this.icon
  });

  static const MartialArtTheme kungFu = MartialArtTheme(
    name: 'Kung Fu',
    primaryColor: Color(0xFFE65100), // Naranja Tradicional Shaolin
    accentColor: Color(0xFFFFA726),
    icon: 'assets/icons/kung-fu.png'
  );

  static final MartialArtTheme taiChi = MartialArtTheme(
    name: 'Tai Chi',
    primaryColor: const Color(0xFF4CAF50), // Un verde sereno
    accentColor: const Color(0xFF81C784),
      icon: 'assets/icons/tai-chi.png'
  );

  static const MartialArtTheme karate = MartialArtTheme(
    name: 'Karate',
    primaryColor: Color(0xFF0D47A1), // Azul profundo
    accentColor: Color(0xFF42A5F5),
      icon: 'assets/icons/karate.png'
  );

  static const MartialArtTheme taekwondo = MartialArtTheme(
    name: 'Taekwondo',
    primaryColor: Color(0xFFD32F2F), // Rojo fuerte
    accentColor: Color(0xFFEF5350),
      icon: 'assets/icons/taekwondo.png'
  );

  static const MartialArtTheme jiuJitsu = MartialArtTheme(
    name: 'Jiu Jitsu',
    primaryColor: Color(0xFF4CAF50), // Verde
    accentColor: Color(0xFF81C784),
      icon: 'assets/icons/jiu-jitsu.png'
  );

  static final MartialArtTheme judo = MartialArtTheme(
    name: 'Judo',
    primaryColor: const Color(0xFF1E88E5), // Azul
    accentColor: const Color(0xFFBBDEFB),
    icon: 'assets/icons/judo.png'
  );

  static final MartialArtTheme boxeo = MartialArtTheme(
    name: 'Boxeo',
    primaryColor: const Color(0xFFD32F2F), // Rojo Intenso
    accentColor: const Color(0xFFFFCDD2),
    icon: 'assets/icons/boxeo.png'
  );

  static final MartialArtTheme kickboxing = MartialArtTheme(
    name: 'Kickboxing',
    primaryColor: const Color(0xFFFF7043), // Naranja
    accentColor: const Color(0xFFFFE0B2),
    icon: 'assets/icons/kickboxing.png'
  );

  static final MartialArtTheme muayThai = MartialArtTheme(
    name: 'Muay Thai',
    primaryColor: const Color(0xFF616161), // Gris Oscuro
    accentColor: const Color(0xFFE0E0E0),
    icon: 'assets/icons/muay-thai.png'
  );

  static final MartialArtTheme kravMaga = MartialArtTheme(
    name: 'Krav Maga',
    primaryColor: const Color(0xFF00796B), // Verde Azulado
    accentColor: const Color(0xFFB2DFDB),
    icon: 'assets/icons/krav-maga.png'
  );

  static final MartialArtTheme aikido = MartialArtTheme(
    name: 'Aikido',
    primaryColor: const Color(0xFF0277BD), // Azul Cielo
    accentColor: const Color(0xFFB3E5FC),
    icon: 'assets/icons/aikido.png'
  );

  static final MartialArtTheme capoeira = MartialArtTheme(
    name: 'Capoeira',
    primaryColor: const Color(0xFF43A047), // Verde Brasil
    accentColor: const Color(0xFFC8E6C9),
    icon: 'assets/icons/capoeira.png'
  );

  static final MartialArtTheme kendo = MartialArtTheme(
    name: 'Kendo',
    primaryColor: const Color(0xFF283593), // Azul Índigo, color tradicional
    accentColor: const Color(0xFF9FA8DA),
    icon: 'assets/icons/kendo.png',
  );

  static final MartialArtTheme mma = MartialArtTheme(
    name: 'MMA',
    primaryColor: const Color(0xFF212121), // Un color oscuro/carbón, muy común en MMA
    accentColor: const Color(0xFFBDBDBD),
    icon: 'assets/icons/mma.png',
  );

  static List<MartialArtTheme> get allThemes => [
    kungFu,
    taiChi,
    karate,
    taekwondo,
    jiuJitsu,
    judo,
    boxeo,
    kickboxing,
    muayThai,
    kravMaga,
    aikido,
    capoeira,
    mma,
    kendo
  ];
}
