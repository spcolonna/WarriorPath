import '../config/achievements_config.dart';

// ── Valor date-only para comparaciones sin hora ────────────────────────────────

class _DateOnly {
  final int year, month, day;
  const _DateOnly(this.year, this.month, this.day);

  @override
  bool operator ==(Object other) =>
      other is _DateOnly &&
      year == other.year &&
      month == other.month &&
      day == other.day;

  @override
  int get hashCode => Object.hash(year, month, day);
}

// ── Estado calculado para un logro ────────────────────────────────────────────

class AchievementStatus {
  final AchievementDef def;

  /// La condición se cumple HOY (independiente del cooldown almacenado).
  final bool conditionMet;

  /// Tiene el logro activo: condición cumplida o dentro de la ventana de gracia.
  final bool isEarned;

  /// Tuvo el logro pero el cooldown expiró sin renovarlo.
  final bool isExpired;

  final DateTime? earnedAt;
  final DateTime? expiresAt;

  const AchievementStatus({
    required this.def,
    required this.conditionMet,
    required this.isEarned,
    required this.isExpired,
    this.earnedAt,
    this.expiresAt,
  });

  /// Días hasta que vence la ventana de gracia (null si no aplica).
  int? get daysRemaining {
    if (expiresAt == null) return null;
    final diff = expiresAt!.difference(DateTime.now()).inDays;
    return diff.clamp(0, 9999);
  }

  bool get hasBeenEarnedBefore => earnedAt != null;
}

// ── Motor de evaluación ───────────────────────────────────────────────────────

class AchievementEngine {
  /// Evalúa todos los logros y devuelve la lista de estados.
  ///
  /// [attendanceDates] — lista de DateTime de cada asistencia registrada
  ///   (incluye hora si está disponible en el Timestamp de Firestore).
  /// [totalTechniques] — total de técnicas asignadas en todas las disciplinas.
  /// [birthday] — fecha de nacimiento del usuario (puede ser null).
  /// [stored] — mapa leído del campo `achievements` del documento member.
  ///   Formato: { "achievement_id": { "earnedAt": Timestamp, "expiresAt": Timestamp? } }
  static List<AchievementStatus> evaluate({
    required List<DateTime> attendanceDates,
    required int totalTechniques,
    required DateTime? birthday,
    required Map<String, dynamic> stored,
  }) {
    final now = DateTime.now();
    final conditions = _computeConditions(
      attendanceDates: attendanceDates,
      totalTechniques: totalTechniques,
      birthday: birthday,
      now: now,
    );

    return kAchievements.map((def) {
      final conditionMet = conditions[def.id] ?? false;
      final storedEntry =
          stored[def.id] as Map<String, dynamic>?;

      DateTime? earnedAt;
      DateTime? expiresAt;

      if (storedEntry != null) {
        earnedAt = (storedEntry['earnedAt'] as dynamic)?.toDate() as DateTime?;
        expiresAt =
            (storedEntry['expiresAt'] as dynamic)?.toDate() as DateTime?;
      }

      bool isEarned;
      bool isExpired;

      if (def.isPermanent) {
        // Logro permanente: se gana para siempre una vez obtenido
        isEarned = conditionMet || earnedAt != null;
        isExpired = false;
        // Si se gana por primera vez, actualizamos earnedAt
        if (conditionMet && earnedAt == null) {
          earnedAt = now;
        }
      } else {
        // Logro con cooldown
        if (conditionMet) {
          // Condición activa → renovar (o ganar por primera vez)
          earnedAt = now;
          expiresAt = now.add(Duration(days: def.cooldownDays!));
          isEarned = true;
          isExpired = false;
        } else if (expiresAt != null && now.isBefore(expiresAt)) {
          // No cumple hoy pero sigue en el período de gracia
          isEarned = true;
          isExpired = false;
        } else if (expiresAt != null && now.isAfter(expiresAt)) {
          // Venció sin renovarse
          isEarned = false;
          isExpired = true;
        } else {
          // Nunca ganado
          isEarned = false;
          isExpired = false;
        }
      }

      return AchievementStatus(
        def: def,
        conditionMet: conditionMet,
        isEarned: isEarned,
        isExpired: isExpired,
        earnedAt: earnedAt,
        expiresAt: isEarned && !def.isPermanent ? expiresAt : null,
      );
    }).toList();
  }

  /// Devuelve qué logros deben escribirse en Firestore (condición recién cumplida
  /// o cooldown renovado). Formato listo para hacer `update()` con dot-notation.
  static Map<String, dynamic> buildFirestoreUpdates(
      List<AchievementStatus> statuses) {
    final updates = <String, dynamic>{};
    for (final s in statuses) {
      if (!s.conditionMet) continue;

      final entry = <String, dynamic>{'earnedAt': s.earnedAt};
      if (s.expiresAt != null) entry['expiresAt'] = s.expiresAt;

      updates['achievements.${s.def.id}'] = entry;
    }
    return updates;
  }

  // ── Cómputo de condiciones ──────────────────────────────────────────────────

  static Map<String, bool> _computeConditions({
    required List<DateTime> attendanceDates,
    required int totalTechniques,
    required DateTime? birthday,
    required DateTime now,
  }) {
    final conditions = <String, bool>{};

    // ── Asistencia ──────────────────────────────────────────────────────────────

    final weekStart = _startOfWeek(now);
    final weekEnd = weekStart.add(const Duration(days: 7));
    final daysThisWeek = attendanceDates
        .where((d) => !d.isBefore(weekStart) && d.isBefore(weekEnd))
        .map((d) => _DateOnly(d.year, d.month, d.day))
        .toSet();
    conditions['weekly_bronze'] = daysThisWeek.length >= kWeeklyMinDays;

    final daysThisMonth = attendanceDates
        .where((d) => d.year == now.year && d.month == now.month)
        .map((d) => d.day)
        .toSet();
    conditions['monthly_silver'] = daysThisMonth.length >= kMonthlyMinDays;

    final monthsThisYear = attendanceDates
        .where((d) => d.year == now.year)
        .map((d) => d.month)
        .toSet();
    conditions['yearly_gold'] = monthsThisYear.length >= kYearlyMinMonths;

    // ── Técnicas ────────────────────────────────────────────────────────────────

    conditions['first_technique'] = totalTechniques >= 1;
    conditions['techniques_10'] = totalTechniques >= 10;
    conditions['techniques_25'] = totalTechniques >= 25;
    conditions['techniques_50'] = totalTechniques >= 50;
    conditions['techniques_100'] = totalTechniques >= 100;

    // ── Especiales ──────────────────────────────────────────────────────────────

    // Madrugador: asistió a una clase antes de kEarlyBirdMaxHour
    // Usa la hora del Timestamp de Firestore (serverTimestamp registra la hora real).
    conditions['early_bird'] =
        attendanceDates.any((d) => d.hour <= kEarlyBirdMaxHour && d.hour > 0);

    // Noctámbulo: asistió a una clase a partir de kNightOwlMinHour
    conditions['night_owl'] =
        attendanceDates.any((d) => d.hour >= kNightOwlMinHour);

    // Guerrero de invierno: asistió en un mes de invierno
    conditions['winter_warrior'] =
        attendanceDates.any((d) => kWinterMonths.contains(d.month));

    // Sin excusas: asistió el día de su cumpleaños
    conditions['no_excuses'] = birthday != null &&
        attendanceDates.any(
            (d) => d.month == birthday.month && d.day == birthday.day);

    return conditions;
  }

  static DateTime _startOfWeek(DateTime date) {
    // Lunes como inicio de semana (weekday: 1=Mon … 7=Sun)
    return DateTime(date.year, date.month, date.day)
        .subtract(Duration(days: date.weekday - 1));
  }
}
