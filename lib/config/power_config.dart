import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

/// Configuración del "Nivel de Poder" y los tiers del avatar.
///
/// Es la fuente de verdad compartida entre:
///  - el avatar HTML/CSS ([avatar_html_builder.dart]),
///  - el mini-avatar nativo del ranking ([mini_avatar.dart]),
///  - la card de poder del hero ([power_level_card.dart]).
///
/// Espeja el patrón de [lib/config/achievements_config.dart].
///
/// IMPORTANTE: los valores reales se otorgan en el backend
/// ([functions/src/index.ts] → `POINTS_PER_CLASS` / `POINTS_PER_EVENT` /
/// `POINTS_PER_PROMOTION`). Estas constantes son sólo para mostrar "+N" en la
/// UI y deben mantenerse sincronizadas con las del backend.
const int kPointsPerClass = 10;

/// Puntos por confirmar asistencia a un evento especial.
const int kPointsPerEvent = 25;

/// Puntos por ser promovido de nivel (faja).
const int kPointsPerPromotion = 50;

/// Variante de avatar derivada de `users.gender`
/// (`'masculino' | 'femenino' | 'otro' | 'prefiero_no_decirlo' | null`).
enum AvatarGender { male, female, neutral }

AvatarGender avatarGenderFromString(String? gender) {
  switch (gender) {
    // Cuentas viejas pueden tener los valores en inglés ('male'/'female').
    case 'masculino':
    case 'male':
      return AvatarGender.male;
    case 'femenino':
    case 'female':
      return AvatarGender.female;
    default:
      return AvatarGender.neutral;
  }
}

extension AvatarGenderSlug on AvatarGender {
  /// Slug usado como clase CSS en el avatar (`g-male` / `g-female` / `g-neutral`).
  String get slug => switch (this) {
        AvatarGender.male => 'male',
        AvatarGender.female => 'female',
        AvatarGender.neutral => 'neutral',
      };
}

/// Un tier del Nivel de Poder.
class PowerTier {
  final int index;

  /// Poder mínimo (inclusive) para estar en este tier.
  final int minPower;

  /// Poder mínimo del tier siguiente (exclusive). `null` en el último tier.
  final int? nextThreshold;

  /// Clave de localización para el nombre del tier.
  final String nameKey;

  /// Color "metal" del tier (aura / cinturón / marco). ARGB.
  final Color metal;

  const PowerTier({
    required this.index,
    required this.minPower,
    required this.nextThreshold,
    required this.nameKey,
    required this.metal,
  });

  bool get isMax => nextThreshold == null;

  /// Color en formato hex `#RRGGBB` para inyectar en el HTML/CSS del avatar.
  String get metalHex =>
      '#${(metal.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
}

/// Definición de los tiers, de menor a mayor.
///
/// Umbrales: Novato 0–99 · Guerrero 100–499 · Veterano 500–999 · Maestro 1000+.
const List<PowerTier> kPowerTiers = [
  PowerTier(
    index: 0,
    minPower: 0,
    nextThreshold: 100,
    nameKey: 'tierNovice',
    metal: Color(0xFF8B93A7), // piedra
  ),
  PowerTier(
    index: 1,
    minPower: 100,
    nextThreshold: 500,
    nameKey: 'tierWarrior',
    metal: Color(0xFFC98A4B), // bronce
  ),
  PowerTier(
    index: 2,
    minPower: 500,
    nextThreshold: 1000,
    nameKey: 'tierVeteran',
    metal: Color(0xFF9FB7D4), // acero
  ),
  PowerTier(
    index: 3,
    minPower: 1000,
    nextThreshold: null,
    nameKey: 'tierMaster',
    metal: Color(0xFFF5C451), // oro
  ),
];

/// Tier correspondiente a un valor de poder.
PowerTier tierForPower(int power) {
  final p = power < 0 ? 0 : power;
  PowerTier result = kPowerTiers.first;
  for (final t in kPowerTiers) {
    if (p >= t.minPower) result = t;
  }
  return result;
}

/// Progreso [0.0, 1.0] dentro del tier actual hacia el siguiente.
/// En el tier máximo devuelve 1.0.
double tierProgress(int power) {
  final tier = tierForPower(power);
  if (tier.isMax) return 1.0;
  final span = tier.nextThreshold! - tier.minPower;
  if (span <= 0) return 1.0;
  final into = (power - tier.minPower).clamp(0, span);
  return into / span;
}

/// Poder que falta para el próximo tier. `null` en el tier máximo.
int? powerToNextTier(int power) {
  final tier = tierForPower(power);
  if (tier.isMax) return null;
  final remaining = tier.nextThreshold! - power;
  return remaining < 0 ? 0 : remaining;
}

/// Nombre localizado de un tier.
String tierName(AppLocalizations l10n, PowerTier tier) {
  switch (tier.index) {
    case 0:
      return l10n.tierNovice;
    case 1:
      return l10n.tierWarrior;
    case 2:
      return l10n.tierVeteran;
    default:
      return l10n.tierMaster;
  }
}
