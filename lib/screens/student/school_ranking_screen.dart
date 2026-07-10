import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../config/power_config.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/avatar/mini_avatar.dart';

/// Ranking de poder de la escuela: lista los miembros activos ordenados por
/// `powerLevel` descendente, con mini-avatar nativo, y resalta al usuario actual.
///
/// Requiere el índice compuesto Firestore (`status` ASC + `powerLevel` DESC) en
/// la subcolección `members`.
class SchoolRankingScreen extends StatelessWidget {
  final String schoolId;
  final String memberId;

  const SchoolRankingScreen({
    super.key,
    required this.schoolId,
    required this.memberId,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final primary = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.schoolRanking)),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('schools')
            .doc(schoolId)
            .collection('members')
            .where('status', isEqualTo: 'active')
            .orderBy('powerLevel', descending: true)
            .limit(100)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  l10n.rankingEmpty,
                  style: TextStyle(color: Colors.grey.shade500),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            itemCount: docs.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final data = docs[i].data();
              final isMe = docs[i].id == memberId;
              final name = data['displayName'] as String? ?? '—';
              final power = (data['powerLevel'] as num?)?.toInt() ?? 0;
              final gender = avatarGenderFromString(data['gender'] as String?);
              final rank = i + 1;

              return _RankRow(
                rank: rank,
                name: name,
                power: power,
                gender: gender,
                schoolColor: primary,
                isMe: isMe,
                youLabel: l10n.rankingYou,
              );
            },
          );
        },
      ),
    );
  }
}

class _RankRow extends StatelessWidget {
  final int rank;
  final String name;
  final int power;
  final AvatarGender gender;
  final Color schoolColor;
  final bool isMe;
  final String youLabel;

  const _RankRow({
    required this.rank,
    required this.name,
    required this.power,
    required this.gender,
    required this.schoolColor,
    required this.isMe,
    required this.youLabel,
  });

  static const _podium = [
    Color(0xFFF5C451), // oro
    Color(0xFFC9CDD6), // plata
    Color(0xFFC98A4B), // bronce
  ];

  @override
  Widget build(BuildContext context) {
    final tier = tierForPower(power);
    final medal = rank <= 3 ? _podium[rank - 1] : null;

    return Container(
      decoration: BoxDecoration(
        color: isMe ? schoolColor.withValues(alpha: 0.10) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isMe ? schoolColor.withValues(alpha: 0.5) : Colors.grey.shade200,
          width: isMe ? 1.5 : 1,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          // Puesto
          SizedBox(
            width: 30,
            child: medal != null
                ? Icon(Icons.emoji_events, color: medal, size: 24)
                : Text(
                    '$rank',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
          ),
          const SizedBox(width: 8),
          MiniAvatar(
            gender: gender,
            power: power,
            schoolColor: schoolColor,
            size: 44,
          ),
          const SizedBox(width: 12),
          // Nombre + tier
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: isMe ? FontWeight.w800 : FontWeight.w600,
                          color: isMe ? schoolColor : Colors.black87,
                        ),
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: schoolColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          youLabel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  tierName(AppLocalizations.of(context), tier),
                  style: TextStyle(
                    fontSize: 12,
                    color: tier.metal,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          // Poder
          Text(
            '⚡ $power',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
