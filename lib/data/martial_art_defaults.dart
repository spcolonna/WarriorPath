import 'package:flutter/material.dart';
import 'package:warrior_path/models/level_model.dart';
import 'package:warrior_path/models/technique_model.dart';

/// Valores por defecto de currícula por arte marcial. Se usan para PRECARGAR
/// (de forma editable) los niveles, categorías y técnicas cuando el profesor
/// configura una disciplina por primera vez. Nada de esto se escribe en la base
/// hasta que el profe guarda: son sugerencias que puede editar o borrar.
///
/// La clave del mapa es el `name` exacto de MartialArtTheme
/// (ver lib/theme/martial_art_themes.dart).
class MartialArtDefaults {
  final String progressionSystemName;

  /// Cinturones/niveles en orden ascendente: (nombre, color ARGB).
  final List<(String, int)> belts;

  final List<String> categories;

  /// Técnicas/formas de ejemplo: (nombre, categoría, complejidad 1-5).
  final List<(String, String, int)> techniques;

  const MartialArtDefaults({
    required this.progressionSystemName,
    required this.belts,
    required this.categories,
    this.techniques = const [],
  });

  /// Cantidad de niveles/cinturones de la plantilla (para mostrar en la UI).
  int get levelCount => belts.length;

  /// Cantidad de técnicas de ejemplo de la plantilla (para mostrar en la UI).
  int get techniqueCount => techniques.length;

  /// ¿Existe una plantilla para este arte marcial? La clave es el `name`
  /// exacto del [MartialArtTheme] (ver lib/theme/martial_art_themes.dart).
  static bool hasTemplate(String artName) =>
      martialArtDefaults.containsKey(artName);

  /// Plantilla para un arte marcial, o null si no hay.
  static MartialArtDefaults? templateFor(String artName) =>
      martialArtDefaults[artName];

  List<LevelModel> toLevels() {
    return [
      for (int i = 0; i < belts.length; i++)
        LevelModel(name: belts[i].$1, color: Color(belts[i].$2), order: i),
    ];
  }

  /// Devuelve las técnicas como modelos con localId incremental arrancando en
  /// [startLocalId] (para encajar con el contador del wizard).
  List<TechniqueModel> toTechniques(int startLocalId) {
    return [
      for (int i = 0; i < techniques.length; i++)
        TechniqueModel(
          name: techniques[i].$1,
          category: techniques[i].$2,
          complexity: techniques[i].$3,
          localId: startLocalId + i,
        ),
    ];
  }
}

// Paleta de colores de cinturón reutilizable.
const int _white = 0xFFFFFFFF;
const int _yellow = 0xFFFFEB3B;
const int _orange = 0xFFFF9800;
const int _green = 0xFF4CAF50;
const int _blue = 0xFF2196F3;
const int _purple = 0xFF9C27B0;
const int _brown = 0xFF795548;
const int _red = 0xFFF44336;
const int _black = 0xFF212121;
const int _grey = 0xFF9E9E9E;

// Escala genérica para deportes de combate sin cinturón (boxeo, MMA, etc.).
const List<(String, int)> _genericScale = [
  ('Principiante', _grey),
  ('Intermedio', _blue),
  ('Avanzado', _orange),
  ('Competidor', _red),
  ('Profesional', _black),
];

const Map<String, MartialArtDefaults> martialArtDefaults = {
  'Karate': MartialArtDefaults(
    progressionSystemName: 'Cinturones',
    belts: [
      ('Cinturón Blanco', _white),
      ('Cinturón Amarillo', _yellow),
      ('Cinturón Naranja', _orange),
      ('Cinturón Verde', _green),
      ('Cinturón Azul', _blue),
      ('Cinturón Marrón', _brown),
      ('Cinturón Negro', _black),
    ],
    categories: ['Kata', 'Kihon', 'Kumite'],
    techniques: [
      ('Heian Shodan', 'Kata', 1),
      ('Heian Nidan', 'Kata', 2),
      ('Heian Sandan', 'Kata', 2),
      ('Heian Yondan', 'Kata', 3),
      ('Heian Godan', 'Kata', 3),
      ('Tekki Shodan', 'Kata', 4),
      ('Bassai Dai', 'Kata', 5),
    ],
  ),
  'Taekwondo': MartialArtDefaults(
    progressionSystemName: 'Cinturones ITF',
    belts: [
      ('10º Gup - Blanco', _white),
      ('9º Gup - Blanco punta amarilla', _white),
      ('8º Gup - Amarillo', _yellow),
      ('7º Gup - Amarillo punta verde', _yellow),
      ('6º Gup - Verde', _green),
      ('5º Gup - Verde punta azul', _green),
      ('4º Gup - Azul', _blue),
      ('3º Gup - Azul punta roja', _blue),
      ('2º Gup - Rojo', _red),
      ('1º Gup - Rojo punta negra', _red),
      ('1º Dan - Negro', _black),
    ],
    categories: ['Tul (Formas)', 'Patadas', 'Defensa personal'],
    techniques: [
      ('Chon-Ji', 'Tul (Formas)', 1),
      ('Dan-Gun', 'Tul (Formas)', 1),
      ('Do-San', 'Tul (Formas)', 2),
      ('Won-Hyo', 'Tul (Formas)', 2),
      ('Yul-Gok', 'Tul (Formas)', 3),
      ('Joong-Gun', 'Tul (Formas)', 3),
      ('Toi-Gye', 'Tul (Formas)', 4),
      ('Hwa-Rang', 'Tul (Formas)', 4),
      ('Choong-Moo', 'Tul (Formas)', 5),
    ],
  ),
  'Jiu Jitsu': MartialArtDefaults(
    progressionSystemName: 'Fajas',
    belts: [
      ('Faja Blanca', _white),
      ('Faja Azul', _blue),
      ('Faja Violeta', _purple),
      ('Faja Marrón', _brown),
      ('Faja Negra', _black),
    ],
    categories: ['Guardia', 'Montada', 'Sumisiones', 'Barridas', 'Defensa'],
  ),
  'Judo': MartialArtDefaults(
    progressionSystemName: 'Cinturones',
    belts: [
      ('Cinturón Blanco', _white),
      ('Cinturón Amarillo', _yellow),
      ('Cinturón Naranja', _orange),
      ('Cinturón Verde', _green),
      ('Cinturón Azul', _blue),
      ('Cinturón Marrón', _brown),
      ('Cinturón Negro', _black),
    ],
    categories: ['Nage-waza (proyecciones)', 'Katame-waza (control)', 'Ukemi (caídas)'],
    techniques: [
      ('O-goshi', 'Nage-waza (proyecciones)', 2),
      ('Ippon-seoi-nage', 'Nage-waza (proyecciones)', 3),
      ('O-soto-gari', 'Nage-waza (proyecciones)', 2),
      ('Kesa-gatame', 'Katame-waza (control)', 2),
    ],
  ),
  'Kung Fu': MartialArtDefaults(
    progressionSystemName: 'Fajas',
    belts: [
      ('Faja Blanca', _white),
      ('Faja Amarilla', _yellow),
      ('Faja Naranja', _orange),
      ('Faja Verde', _green),
      ('Faja Azul', _blue),
      ('Faja Marrón', _brown),
      ('Faja Roja', _red),
      ('Faja Negra', _black),
    ],
    categories: [
      'Puños y Golpes',
      'Patadas',
      'Formas (Taolu)',
      'Chi Kung',
      'Defensa Personal',
      'Armas',
    ],
    techniques: [
      ('Wu Bu Quan (Forma de Cinco Pasos)', 'Formas (Taolu)', 1),
      ('Xiao Hong Quan (Forma Pequeña Roja)', 'Formas (Taolu)', 2),
      ('Lian Huan Quan', 'Formas (Taolu)', 3),
      ('Yi Jin Jing', 'Chi Kung', 2),
    ],
  ),
  'Tai Chi': MartialArtDefaults(
    progressionSystemName: 'Formas',
    belts: [
      ('Forma 8', _grey),
      ('Forma 24', _blue),
      ('Forma 42', _green),
      ('Forma 108', _black),
    ],
    categories: ['Formas', 'Chi Kung', 'Empuje de Manos (Tui Shou)'],
  ),
  'Aikido': MartialArtDefaults(
    progressionSystemName: 'Cinturones (Kyu/Dan)',
    belts: [
      ('6º Kyu - Blanco', _white),
      ('5º Kyu - Amarillo', _yellow),
      ('4º Kyu - Naranja', _orange),
      ('3º Kyu - Verde', _green),
      ('2º Kyu - Azul', _blue),
      ('1º Kyu - Marrón', _brown),
      ('1º Dan - Negro', _black),
    ],
    categories: ['Nage-waza (proyecciones)', 'Katame-waza (controles)', 'Buki-waza (armas)'],
    techniques: [
      ('Ikkyo', 'Katame-waza (controles)', 1),
      ('Nikyo', 'Katame-waza (controles)', 2),
      ('Sankyo', 'Katame-waza (controles)', 2),
      ('Shiho-nage', 'Nage-waza (proyecciones)', 3),
      ('Irimi-nage', 'Nage-waza (proyecciones)', 3),
    ],
  ),
  'Capoeira': MartialArtDefaults(
    progressionSystemName: 'Cordas',
    belts: [
      ('Corda Crua', _white),
      ('Corda Amarela', _yellow),
      ('Corda Laranja', _orange),
      ('Corda Azul', _blue),
      ('Corda Verde', _green),
      ('Corda Marrom', _brown),
      ('Corda Vermelha', _red),
    ],
    categories: ['Movimentos', 'Golpes', 'Esquivas', 'Música'],
  ),
  'Kendo': MartialArtDefaults(
    progressionSystemName: 'Grados (Kyu/Dan)',
    belts: [
      ('6º Kyu', _grey),
      ('5º Kyu', _grey),
      ('4º Kyu', _grey),
      ('3º Kyu', _grey),
      ('2º Kyu', _grey),
      ('1º Kyu', _grey),
      ('1º Dan (Shodan)', _black),
      ('2º Dan (Nidan)', _black),
    ],
    categories: ['Kihon (básicos)', 'Kata', 'Waza (técnicas)'],
  ),
  'Krav Maga': MartialArtDefaults(
    progressionSystemName: 'Niveles (Practicante)',
    belts: [
      ('Practicante 1 (P1)', _yellow),
      ('Practicante 2 (P2)', _orange),
      ('Practicante 3 (P3)', _green),
      ('Practicante 4 (P4)', _blue),
      ('Practicante 5 (P5)', _brown),
    ],
    categories: ['Golpes', 'Defensas', 'Liberaciones', 'Amenazas con arma'],
  ),
  // --- Deportes de combate sin cinturón: escala genérica editable ---
  'Boxeo': MartialArtDefaults(
    progressionSystemName: 'Categorías',
    belts: _genericScale,
    categories: ['Golpes', 'Defensa', 'Combinaciones', 'Trabajo de piernas'],
  ),
  'Kickboxing': MartialArtDefaults(
    progressionSystemName: 'Categorías',
    belts: _genericScale,
    categories: ['Golpes de puño', 'Patadas', 'Combinaciones', 'Defensa'],
  ),
  'Muay Thai': MartialArtDefaults(
    progressionSystemName: 'Categorías',
    belts: _genericScale,
    categories: ['Puños', 'Codos', 'Rodillas', 'Patadas', 'Clinch'],
  ),
  'MMA': MartialArtDefaults(
    progressionSystemName: 'Categorías',
    belts: _genericScale,
    categories: ['Striking', 'Grappling', 'Wrestling', 'Clinch', 'Ground and Pound'],
  ),
};
