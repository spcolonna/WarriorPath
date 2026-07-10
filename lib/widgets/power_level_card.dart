import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../config/power_config.dart';
import '../l10n/app_localizations.dart';
import '../screens/student/school_ranking_screen.dart';
import 'avatar/warrior_avatar_view.dart';

/// Card "hero" de la pantalla principal del alumno: muestra el avatar cabezón
/// (HTML/CSS en WebView) junto al Nivel de Poder, el tier y el progreso al
/// siguiente tier. Al tocarla abre el ranking de la escuela.
///
/// Lee el poder en tiempo real del documento del miembro
/// (`schools/{schoolId}/members/{memberId}.powerLevel`) y el género de
/// `members.gender` (denormalizado) con fallback a `users/{memberId}.gender`.
class PowerLevelCard extends StatefulWidget {
  final String schoolId;
  final String memberId;

  const PowerLevelCard({
    super.key,
    required this.schoolId,
    required this.memberId,
  });

  @override
  State<PowerLevelCard> createState() => _PowerLevelCardState();
}

class _PowerLevelCardState extends State<PowerLevelCard> {
  AvatarGender? _gender;
  bool _resolvingGender = false;

  DocumentReference<Map<String, dynamic>> get _memberRef =>
      FirebaseFirestore.instance
          .collection('schools')
          .doc(widget.schoolId)
          .collection('members')
          .doc(widget.memberId);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final primary = Theme.of(context).primaryColor;

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _memberRef.snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data();
        final power = (data?['powerLevel'] as num?)?.toInt() ?? 0;

        // Género: preferir el denormalizado en member; si falta, ir a users.
        final memberGender = data?['gender'] as String?;
        if (memberGender != null && _gender == null) {
          _gender = avatarGenderFromString(memberGender);
        } else if (memberGender == null && _gender == null && !_resolvingGender) {
          _resolveGenderFromUser();
        }
        final gender = _gender ?? AvatarGender.neutral;

        final tier = tierForPower(power);
        final remaining = powerToNextTier(power);
        final progress = tierProgress(power);

        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => SchoolRankingScreen(
                    schoolId: widget.schoolId,
                    memberId: widget.memberId,
                  ),
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      primary,
                      Color.lerp(primary, Colors.black, 0.42)!,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: primary.withValues(alpha: 0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                padding: const EdgeInsets.fromLTRB(16, 16, 20, 18),
                child: Row(
                  children: [
                    // Avatar hero
                    SizedBox(
                      width: 116,
                      height: 128,
                      child: WarriorAvatarView(
                        gender: gender,
                        power: power,
                        schoolColor: primary,
                        size: 116,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Stats
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: tier.metal,
                                  boxShadow: [
                                    BoxShadow(
                                      color: tier.metal.withValues(alpha: 0.8),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                tierName(l10n, tier),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            l10n.powerLevel.toUpperCase(),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 11,
                              letterSpacing: 1.2,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              const Text('⚡ ',
                                  style: TextStyle(fontSize: 20)),
                              Text(
                                '$power',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 30,
                                  fontWeight: FontWeight.w900,
                                  height: 1,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Barra de progreso al próximo tier
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 7,
                              backgroundColor:
                                  Colors.white.withValues(alpha: 0.22),
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(tier.metal),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            remaining == null
                                ? l10n.maxTierReached
                                : l10n.pointsToNextTier(remaining),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right,
                        color: Colors.white.withValues(alpha: 0.6)),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _resolveGenderFromUser() async {
    _resolvingGender = true;
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.memberId)
          .get();
      if (!mounted) return;
      setState(() {
        _gender = avatarGenderFromString(userDoc.data()?['gender'] as String?);
      });
    } catch (_) {
      if (mounted) setState(() => _gender = AvatarGender.neutral);
    }
  }
}
