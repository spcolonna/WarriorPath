import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../config/power_config.dart';
import '../l10n/app_localizations.dart';
import '../screens/student/school_ranking_screen.dart';
import 'avatar/mini_avatar.dart';

/// Card con el top-N del ranking de poder de la escuela y acceso al ranking
/// completo. Se usa en el tab de progreso del alumno y en la home del maestro.
class SchoolRankingPreview extends StatelessWidget {
  final String schoolId;

  /// Id del member del usuario actual (para resaltar su fila en el ranking
  /// completo). Para el maestro es su propio uid.
  final String memberId;
  final int topCount;

  const SchoolRankingPreview({
    super.key,
    required this.schoolId,
    required this.memberId,
    this.topCount = 3,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final primary = Theme.of(context).primaryColor;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.emoji_events, color: primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  l10n.schoolRanking,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('schools')
                  .doc(schoolId)
                  .collection('members')
                  .where('status', isEqualTo: 'active')
                  .orderBy('powerLevel', descending: true)
                  .limit(topCount)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(l10n.rankingEmpty,
                        style: TextStyle(color: Colors.grey.shade500)),
                  );
                }
                return Column(
                  children: [
                    for (int i = 0; i < docs.length; i++)
                      _RankPreviewRow(
                        rank: i + 1,
                        data: docs[i].data(),
                        primary: primary,
                      ),
                  ],
                );
              },
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => SchoolRankingScreen(
                      schoolId: schoolId,
                      memberId: memberId,
                    ),
                  ),
                ),
                child: Text(l10n.viewFullRanking),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RankPreviewRow extends StatelessWidget {
  final int rank;
  final Map<String, dynamic> data;
  final Color primary;

  const _RankPreviewRow({
    required this.rank,
    required this.data,
    required this.primary,
  });

  static const _medals = [
    Color(0xFFF5C451),
    Color(0xFFC9CDD6),
    Color(0xFFC98A4B),
  ];

  @override
  Widget build(BuildContext context) {
    final name = data['displayName'] as String? ?? '—';
    final power = (data['powerLevel'] as num?)?.toInt() ?? 0;
    final gender = avatarGenderFromString(data['gender'] as String?);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: rank <= 3
                ? Icon(Icons.emoji_events, color: _medals[rank - 1], size: 18)
                : Text('$rank',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 6),
          MiniAvatar(
              gender: gender, power: power, schoolColor: primary, size: 34),
          const SizedBox(width: 10),
          Expanded(
            child: Text(name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600)),
          ),
          Text('⚡ $power',
              style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontFeatures: [FontFeature.tabularFigures()])),
        ],
      ),
    );
  }
}
