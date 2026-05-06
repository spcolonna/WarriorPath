// ─────────────────────────────────────────────────────────────────────────────
// Archivo de configuración de logros — editar aquí para ajustar umbrales
// sin tocar la lógica de evaluación ni la UI.
// ─────────────────────────────────────────────────────────────────────────────

// ── Umbrales de asistencia ────────────────────────────────────────────────────

/// Días distintos en la semana actual para ganar "Semana completa"
const int kWeeklyMinDays = 3;

/// Días distintos en el mes actual para ganar "Mes completo"
const int kMonthlyMinDays = 10;

/// Meses distintos en el año actual para ganar "Año completo"
const int kYearlyMinMonths = 10;

// ── Umbrales de tiempo ────────────────────────────────────────────────────────

/// Hora máxima (24h) para que una clase cuente como "Madrugador" (≤ esta hora)
const int kEarlyBirdMaxHour = 8;

/// Hora mínima (24h) para que una clase cuente como "Noctámbulo" (≥ esta hora)
const int kNightOwlMinHour = 20;

// ── Meses de invierno ─────────────────────────────────────────────────────────

/// Meses que se consideran invierno (hemisferio sur: junio, julio, agosto).
/// Cambiar a [12, 1, 2] para hemisferio norte.
const List<int> kWinterMonths = [6, 7, 8];

// ── Hitos de técnicas ─────────────────────────────────────────────────────────

/// Cantidad de técnicas necesarias para cada hito de dominio
const List<int> kTechniqueMilestones = [10, 25, 50, 100];

// ─────────────────────────────────────────────────────────────────────────────
// Modelos de definición — NO modificar salvo para agregar nuevos logros
// ─────────────────────────────────────────────────────────────────────────────

enum AchievementType { attendance, technique, special }

class AchievementDef {
  final String id;
  final String emoji;
  final String title;
  final String description;

  /// null = logro permanente (nunca se pierde).
  /// int = días de vigencia; si no se renueva en ese tiempo, se pierde.
  final int? cooldownDays;

  final AchievementType type;

  /// Posición 0-based en el spritesheet (lectura izquierda→derecha, arriba→abajo).
  /// row = spriteIndex ~/ 3,  col = spriteIndex % 3
  final int spriteIndex;

  const AchievementDef({
    required this.id,
    required this.emoji,
    required this.title,
    required this.description,
    this.cooldownDays,
    required this.type,
    required this.spriteIndex,
  });

  bool get isPermanent => cooldownDays == null;
}

// ─────────────────────────────────────────────────────────────────────────────
// Lista maestra de logros
// ─────────────────────────────────────────────────────────────────────────────

const List<AchievementDef> kAchievements = [
  // ── Asistencia (con cooldown) ───────────────────────────────────────────────
  AchievementDef(
    id: 'weekly_bronze',
    emoji: '🥉',
    title: 'Semana completa',
    description:
        'Asististe al menos $kWeeklyMinDays días distintos en la semana actual.',
    cooldownDays: 7,
    type: AchievementType.attendance,
    spriteIndex: 0,
  ),
  AchievementDef(
    id: 'monthly_silver',
    emoji: '🥈',
    title: 'Mes completo',
    description:
        'Asististe al menos $kMonthlyMinDays días distintos en el mes actual.',
    cooldownDays: 30,
    type: AchievementType.attendance,
    spriteIndex: 1,
  ),
  AchievementDef(
    id: 'yearly_gold',
    emoji: '🥇',
    title: 'Año completo',
    description:
        'Asististe en al menos $kYearlyMinMonths meses distintos durante el año.',
    cooldownDays: 365,
    type: AchievementType.attendance,
    spriteIndex: 2,
  ),

  // ── Técnica y aprendizaje (permanentes) ────────────────────────────────────
  AchievementDef(
    id: 'first_technique',
    emoji: '📖',
    title: 'Primera técnica',
    description: 'Aprendiste tu primera técnica.',
    type: AchievementType.technique,
    spriteIndex: 3,
  ),
  AchievementDef(
    id: 'techniques_10',
    emoji: '⚡',
    title: 'Técnico',
    description: 'Dominaste 10 técnicas.',
    type: AchievementType.technique,
    spriteIndex: 4,
  ),
  AchievementDef(
    id: 'techniques_25',
    emoji: '🔥',
    title: 'Experto',
    description: 'Dominaste 25 técnicas.',
    type: AchievementType.technique,
    spriteIndex: 5,
  ),
  AchievementDef(
    id: 'techniques_50',
    emoji: '🌟',
    title: 'Maestro',
    description: 'Dominaste 50 técnicas.',
    type: AchievementType.technique,
    spriteIndex: 6,
  ),
  AchievementDef(
    id: 'techniques_100',
    emoji: '💎',
    title: 'Leyenda',
    description: 'Dominaste 100 técnicas.',
    type: AchievementType.technique,
    spriteIndex: 7,
  ),

  // ── Especiales y divertidos (permanentes) ──────────────────────────────────
  AchievementDef(
    id: 'early_bird',
    emoji: '🌅',
    title: 'Madrugador',
    description:
        'Asististe a la clase más temprana del día (antes de las $kEarlyBirdMaxHour:00 hs).',
    type: AchievementType.special,
    spriteIndex: 8,
  ),
  AchievementDef(
    id: 'night_owl',
    emoji: '🦉',
    title: 'Noctámbulo',
    description:
        'Asististe a la clase nocturna (desde las $kNightOwlMinHour:00 hs).',
    type: AchievementType.special,
    spriteIndex: 9,
  ),
  AchievementDef(
    id: 'winter_warrior',
    emoji: '❄️',
    title: 'Guerrero de invierno',
    description: 'Asististe durante los meses más fríos del año.',
    type: AchievementType.special,
    spriteIndex: 10,
  ),
  AchievementDef(
    id: 'no_excuses',
    emoji: '🎂',
    title: 'Sin excusas',
    description: 'Asististe el día de tu cumpleaños.',
    type: AchievementType.special,
    spriteIndex: 11,
  ),
];
