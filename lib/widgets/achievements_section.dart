import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter/material.dart';

import '../config/achievements_config.dart';

import '../l10n/app_localizations.dart';

import '../services/achievement_engine.dart';

import 'sprite_icon.dart';

// ── Spritesheet config ────────────────────────────────────────────────────────

const _kSheetPath = 'assets/achievements/achievements_sheet.png';
const _kSheetCols = 3;
const _kSheetRows = 4;
const _kIconSize = 84.0;
const _kCardSize = 100.0;

// ── Ajuste fino del recorte (tunear aquí si los íconos quedan descentrados) ──
// cropFraction : qué fracción de min(cellW,cellH) se recorta como cuadrado.
//   1.0 = celda completa · 0.90 = agrega ~5% de margen por lado
// cropOffsetDx : desplazamiento horizontal (fracción de cellW, + = derecha)
// cropOffsetDy : desplazamiento vertical (fracción de cellH, + = abajo, - = arriba)
const _kCropFraction = 0.92;
const _kCropDx = 0.0;
const _kCropDyRow0 = 0.1; // fila 0
const _kCropDyRow1 = -0.05; // fila 1
const _kCropDyRow2 = -0.2; // fila 2
const _kCropDyRow3 = -0.3; // fila 3 (última)

const _kCropDyPerRow = [_kCropDyRow0, _kCropDyRow1, _kCropDyRow2, _kCropDyRow3];

const _kGrayscale = ColorFilter.matrix(<double>[
  0.2126,
  0.7152,
  0.0722,
  0,
  0,

  0.2126,
  0.7152,
  0.0722,
  0,
  0,

  0.2126,
  0.7152,
  0.0722,
  0,
  0,

  0,
  0,
  0,
  1,
  0,
]);

const _kGrayscaleFaded = ColorFilter.matrix(<double>[
  0.2126,
  0.7152,
  0.0722,
  0,
  0,

  0.2126,
  0.7152,
  0.0722,
  0,
  0,

  0.2126,
  0.7152,
  0.0722,
  0,
  0,

  0,
  0,
  0,
  0.4,
  0,
]);

// ── Data model ────────────────────────────────────────────────────────────────

class _AchievementData {
  final List<AchievementStatus> statuses;

  final Map<String, dynamic> firestoreUpdates;

  const _AchievementData(this.statuses, this.firestoreUpdates);
}

// ── Widget principal ──────────────────────────────────────────────────────────

class AchievementsSection extends StatefulWidget {
  final String schoolId;

  final String memberId;

  final Map<String, dynamic> memberProgress;

  const AchievementsSection({
    super.key,

    required this.schoolId,

    required this.memberId,

    required this.memberProgress,
  });

  @override
  State<AchievementsSection> createState() => _AchievementsSectionState();
}

class _AchievementsSectionState extends State<AchievementsSection> {
  late Future<_AchievementData> _future;

  @override
  void initState() {
    super.initState();

    _future = _loadAndEvaluate();
  }

  Future<_AchievementData> _loadAndEvaluate() async {
    final firestore = FirebaseFirestore.instance;

    final schoolRef = firestore.collection('schools').doc(widget.schoolId);

    final memberRef = schoolRef.collection('members').doc(widget.memberId);

    final attendanceSnap = await schoolRef
        .collection('attendanceRecords')
        .where('presentStudentIds', arrayContains: widget.memberId)
        .get();

    final attendanceDates = attendanceSnap.docs
        .map((d) => (d.data()['date'] as Timestamp?)?.toDate())
        .whereType<DateTime>()
        .toList();

    int totalTechniques = 0;

    for (final disciplineProgress in widget.memberProgress.values) {
      final map = disciplineProgress as Map<String, dynamic>? ?? {};

      final ids = List<String>.from(map['assignedTechniqueIds'] ?? []);

      totalTechniques += ids.length;
    }

    DateTime? birthday;

    try {
      final userDoc = await firestore
          .collection('users')
          .doc(widget.memberId)
          .get();

      final dob = userDoc.data()?['dateOfBirth'];

      if (dob is Timestamp) birthday = dob.toDate();
    } catch (_) {}

    Map<String, dynamic> stored = {};

    try {
      final memberSnap = await memberRef.get();

      stored =
          (memberSnap.data()?['achievements'] as Map<String, dynamic>?) ?? {};
    } catch (_) {}

    final statuses = AchievementEngine.evaluate(
      attendanceDates: attendanceDates,

      totalTechniques: totalTechniques,

      birthday: birthday,

      stored: stored,
    );

    final updates = AchievementEngine.buildFirestoreUpdates(statuses);

    if (updates.isNotEmpty) {
      try {
        await memberRef.update(updates);
      } catch (_) {}
    }

    return _AchievementData(statuses, updates);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_AchievementData>(
      future: _future,

      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),

            child: Center(child: CircularProgressIndicator()),
          );
        }

        final statuses = snapshot.data?.statuses ?? [];

        if (statuses.isEmpty) return const SizedBox.shrink();

        final earned = statuses.where((s) => s.isEarned).toList();

        final rest = statuses.where((s) => !s.isEarned).toList();

        final ordered = [...earned, ...rest];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,

          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),

              child: Row(
                children: [
                  Icon(
                    Icons.emoji_events,

                    size: 24,
                    color: Colors.amber.shade700,
                  ),

                  const SizedBox(width: 8),

                  Text(
                    AppLocalizations.of(context).yourAchievements,

                    style: Theme.of(context).textTheme.headlineSmall,
                  ),

                  const SizedBox(width: 8),

                  _CountBadge(count: earned.length, total: statuses.length),
                ],
              ),
            ),

            const SizedBox(height: 16),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),

              child: Wrap(
                spacing: 12,

                runSpacing: 16,

                alignment: WrapAlignment.center,

                crossAxisAlignment: WrapCrossAlignment.start,

                children: ordered
                    .map((s) => _AchievementBadge(status: s))
                    .toList(),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ── Counter badge ─────────────────────────────────────────────────────────────

class _CountBadge extends StatelessWidget {
  final int count;

  final int total;

  const _CountBadge({required this.count, required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),

      decoration: BoxDecoration(
        color: count > 0
            ? Colors.amber.withValues(alpha: 0.2)
            : Colors.grey.shade200,

        borderRadius: BorderRadius.circular(12),
      ),

      child: Text(
        '$count / $total',

        style: TextStyle(
          fontSize: 13,

          fontWeight: FontWeight.bold,

          color: count > 0 ? Colors.amber.shade800 : Colors.grey,
        ),
      ),
    );
  }
}

// ── Badge individual ──────────────────────────────────────────────────────────

class _AchievementBadge extends StatelessWidget {
  final AchievementStatus status;

  const _AchievementBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final def = status.def;

    final hasCooldown = status.isEarned && !def.isPermanent;

    final daysLeft = status.daysRemaining;

    return GestureDetector(
      onTap: () => _showDetail(context),

      child: SizedBox(
        width: _kCardSize,

        child: Column(
          mainAxisSize: MainAxisSize.min,

          children: [
            // ── Tarjeta cuadrada con icono centrado ────────────────────
            _buildCard(context, def),

            const SizedBox(height: 6),

            // ── Nombre debajo ──────────────────────────────────────────
            Text(
              def.title,

              textAlign: TextAlign.center,

              maxLines: 2,

              overflow: TextOverflow.ellipsis,

              style: TextStyle(
                fontSize: 11,

                fontWeight: status.isEarned
                    ? FontWeight.bold
                    : FontWeight.normal,

                color: status.isEarned
                    ? Colors.grey.shade800
                    : Colors.grey.shade400,

                height: 1.2,
              ),
            ),

            // ── Cooldown debajo del nombre ─────────────────────────────
            if (hasCooldown && daysLeft != null) ...[
              const SizedBox(height: 4),

              _CooldownChip(daysLeft: daysLeft),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, AchievementDef def) {
    // Elegir filtro según estado

    final ColorFilter? filter = status.isEarned
        ? null
        : status.isExpired
        ? _kGrayscale
        : _kGrayscaleFaded;

    final int spriteRow = def.spriteIndex ~/ _kSheetCols;
    final double dy =
        _kCropDyPerRow[spriteRow.clamp(0, _kCropDyPerRow.length - 1)];

    final icon = SpriteIcon(
      assetPath: _kSheetPath,
      spriteIndex: def.spriteIndex,
      totalCols: _kSheetCols,
      totalRows: _kSheetRows,
      size: _kIconSize,
      colorFilter: filter,
      cropFraction: _kCropFraction,
      cropOffsetDx: _kCropDx,
      cropOffsetDy: dy,
      fallback: Text(
        def.emoji,
        style: const TextStyle(fontSize: 36),
        textAlign: TextAlign.center,
      ),
    );

    // Estilo del contenedor según estado

    final BoxDecoration decoration;

    Widget? badge;

    if (status.isEarned) {
      decoration = BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF7B5C0A), // dark burnished

            Color(0xFFD4A843), // metallic mid

            Color(0xFFF0D878), // champagne highlight

            Color(0xFFC8992C), // metallic mid

            Color(0xFF8B6010), // dark burnished
          ],

          stops: [0.0, 0.25, 0.5, 0.75, 1.0],

          begin: Alignment.topLeft,

          end: Alignment.bottomRight,
        ),

        borderRadius: BorderRadius.circular(18),

        boxShadow: [
          BoxShadow(
            color: Color(0xFFD4AF37).withValues(alpha: 0.45),

            blurRadius: 14,

            offset: const Offset(0, 5),
          ),
        ],
      );

      badge = const Positioned(
        top: 6,

        right: 6,

        child: Icon(Icons.check_circle, color: Colors.white, size: 16),
      );
    } else if (status.isExpired) {
      decoration = BoxDecoration(
        color: Colors.grey.shade200,

        borderRadius: BorderRadius.circular(18),

        border: Border.all(color: Colors.red.shade300, width: 1.5),
      );

      badge = Positioned(
        top: 5,

        right: 5,

        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),

          decoration: BoxDecoration(
            color: Colors.red.shade400,

            borderRadius: BorderRadius.circular(6),
          ),

          child: Text(
            AppLocalizations.of(context).achievementExpiredBadge,
            style: const TextStyle(
              fontSize: 7,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    } else {
      decoration = BoxDecoration(
        color: Colors.grey.shade100,

        borderRadius: BorderRadius.circular(18),

        border: Border.all(color: Colors.grey.shade300),
      );
    }

    return Container(
      width: _kCardSize,

      height: _kCardSize,

      decoration: decoration,

      child: Stack(
        children: [
          Center(child: icon),

          if (badge != null) badge,
        ],
      ),
    );
  }

  void _showDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,

      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),

      builder: (_) => _AchievementDetailSheet(status: status),
    );
  }
}

// ── Chip de cooldown ──────────────────────────────────────────────────────────

class _CooldownChip extends StatelessWidget {
  final int daysLeft;

  const _CooldownChip({required this.daysLeft});

  @override
  Widget build(BuildContext context) {
    final urgent = daysLeft <= 1;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),

      decoration: BoxDecoration(
        color: urgent ? Colors.red.shade50 : Colors.amber.shade50,

        borderRadius: BorderRadius.circular(8),

        border: Border.all(
          color: urgent ? Colors.red.shade200 : Colors.amber.shade200,
        ),
      ),

      child: Text(
        daysLeft == 0 ? '¡Hoy expira!' : '$daysLeft días',

        style: TextStyle(
          fontSize: 10,

          fontWeight: FontWeight.bold,

          color: urgent ? Colors.red.shade700 : Colors.amber.shade800,
        ),
      ),
    );
  }
}

// ── Bottom sheet de detalle ───────────────────────────────────────────────────

class _AchievementDetailSheet extends StatelessWidget {
  final AchievementStatus status;

  const _AchievementDetailSheet({required this.status});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final def = status.def;
    final isEarned = status.isEarned;
    final isExpired = status.isExpired;
    final daysLeft = status.daysRemaining;

    final accentColor = isEarned
        ? Colors.amber.shade700
        : isExpired
            ? Colors.red.shade400
            : Colors.grey.shade500;

    final IconData stateIcon;
    final String stateText;

    if (isEarned && def.isPermanent) {
      stateIcon = Icons.check_circle;
      stateText = l10n.achievementPermanent;
    } else if (isEarned && daysLeft != null) {
      stateIcon = Icons.timer_outlined;
      stateText = daysLeft == 0
          ? l10n.achievementExpiresToday
          : l10n.achievementExpiresInDays(daysLeft, daysLeft == 1 ? '' : 's');
    } else if (isExpired) {
      stateIcon = Icons.heart_broken_outlined;
      stateText = l10n.achievementExpired;
    } else {
      stateIcon = Icons.lock_outline;
      stateText = l10n.achievementNotObtained;
    }

    final ColorFilter? filter = isEarned
        ? null
        : isExpired
            ? _kGrayscale
            : _kGrayscaleFaded;

    final int spriteRow = def.spriteIndex ~/ _kSheetCols;
    final double dy =
        _kCropDyPerRow[spriteRow.clamp(0, _kCropDyPerRow.length - 1)];

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          SpriteIcon(
            assetPath: _kSheetPath,
            spriteIndex: def.spriteIndex,
            totalCols: _kSheetCols,
            totalRows: _kSheetRows,
            size: 80,
            colorFilter: filter,
            cropFraction: _kCropFraction,
            cropOffsetDx: _kCropDx,
            cropOffsetDy: dy,
            fallback: Icon(Icons.emoji_events, size: 56, color: accentColor),
          ),
          const SizedBox(height: 12),
          Text(
            def.title,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            def.description,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.4),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: accentColor.withValues(alpha: 0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(stateIcon, size: 15, color: accentColor),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    stateText,
                    style: TextStyle(
                      color: accentColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (!def.isPermanent) ...[
            const SizedBox(height: 8),
            Text(
              l10n.achievementRenews(def.cooldownDays!),
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              textAlign: TextAlign.center,
            ),
          ],
          if (status.earnedAt != null) ...[
            const SizedBox(height: 8),
            Text(
              l10n.achievementObtainedOn(_fmt(status.earnedAt!)),
              style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
            ),
          ],
        ],
      ),
    );
  }

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}
