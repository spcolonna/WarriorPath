import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:confetti/confetti.dart';
import 'package:warrior_path/providers/session_provider.dart';
import 'package:warrior_path/providers/theme_provider.dart';
import 'package:warrior_path/screens/student/tabs/community_tab_screen.dart';
import 'package:warrior_path/screens/student/tabs/payments_tab_screen.dart';
import 'package:warrior_path/screens/student/tabs/profile_tab_screen.dart';
import 'package:warrior_path/screens/student/tabs/progress_tab_screen.dart';
import 'package:warrior_path/screens/student/tabs/school_info_tab_screen.dart';
import 'package:warrior_path/services/achievement_engine.dart';
import 'package:warrior_path/services/local_notification_service.dart';
import 'package:warrior_path/widgets/achievement_unlock_overlay.dart';

import '../../l10n/app_localizations.dart';

class StudentDashboardScreen extends StatefulWidget {
  /// Pestaña en la que abrir: la usan los deep links de notificaciones para
  /// llevar al alumno directo a lo que le avisaron (p. ej. Pagos).
  final int initialTabIndex;

  const StudentDashboardScreen({super.key, this.initialTabIndex = 0});

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  late AppLocalizations l10n;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    l10n = AppLocalizations.of(context);
  }

  int _selectedIndex = 0;
  late ConfettiController _confettiController;
  List<AchievementStatus> _pendingAchievements = [];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialTabIndex;
    _confettiController = ConfettiController(duration: const Duration(seconds: 4));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final session = Provider.of<SessionProvider>(context, listen: false);
      if (session.activeSchoolId != null) {
        Provider.of<ThemeProvider>(context, listen: false)
            .loadThemeFromSchool(session.activeSchoolId!);
      }
      _checkUnseenPromotion();
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _checkUnseenPromotion() async {
    final session = Provider.of<SessionProvider>(context, listen: false);
    final schoolId = session.activeSchoolId;

    final memberId = session.activeProfileId;

    if (schoolId == null || memberId == null) return;

    final memberDoc = await FirebaseFirestore.instance
        .collection('schools').doc(schoolId)
        .collection('members').doc(memberId)
        .get();

    if (!memberDoc.exists) return;

    final hasUnseenPromotion = memberDoc.data()?['hasUnseenPromotion'] ?? false;

    if (hasUnseenPromotion) {
      _showPromotionCelebration(schoolId, memberDoc.data()?['currentLevelId']);
    }
  }

  void _showPromotionCelebration(String schoolId, String? newLevelId) async {
    final session = Provider.of<SessionProvider>(context, listen: false);
    final memberId = session.activeProfileId;

    if (memberId == null || newLevelId == null) return;

    final levelDoc = await FirebaseFirestore.instance.collection('schools').doc(schoolId).collection('levels').doc(newLevelId).get();
    final newLevelName = levelDoc.data()?['name'] ?? 'un nuevo nivel';

    _confettiController.play();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¡Felicitaciones!'),
        content: Text('¡Has sido promovido a $newLevelName!'),
        actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Genial'))],
      ),
    );

    await FirebaseFirestore.instance.collection('schools').doc(schoolId).collection('members').doc(memberId).update({
      'hasUnseenPromotion': false,
    });
  }

  void _onNewAchievements(List<AchievementStatus> achievements) {
    if (!mounted || achievements.isEmpty) return;
    setState(() => _pendingAchievements = achievements);
    for (final a in achievements) {
      LocalNotificationService.showAchievementUnlocked(a);
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = Provider.of<SessionProvider>(context);
    final schoolId = session.activeSchoolId;
    final memberId = session.activeProfileId;

    if (schoolId == null || memberId == null) {
      return Scaffold(body: Center(child: Text(l10n.errorNoActiveSession)));
    }

    final List<Widget> widgetOptions = <Widget>[
      SchoolInfoTabScreen(schoolId: schoolId),
      ProgressTabScreen(
        schoolId: schoolId,
        memberId: memberId,
        onNewAchievements: _onNewAchievements,
      ),
      CommunityTabScreen(schoolId: schoolId),
      PaymentsTabScreen(schoolId: schoolId, memberId: memberId),
      StudentProfileTabScreen(memberId: memberId),
    ];

    return Stack(
      alignment: Alignment.topCenter,
      children: [
        Scaffold(
          body: IndexedStack(
            index: _selectedIndex,
            children: widgetOptions,
          ),
          bottomNavigationBar: _StudentBottomNav(
            selectedIndex: _selectedIndex,
            onTap: _onItemTapped,
            schoolId: schoolId,
            memberId: memberId,
          ),
        ),
        ConfettiWidget(
          confettiController: _confettiController,
          blastDirectionality: BlastDirectionality.explosive,
          shouldLoop: false,
          numberOfParticles: 50,
          emissionFrequency: 0.05,
          gravity: 0.2,
        ),
        if (_pendingAchievements.isNotEmpty)
          Positioned.fill(
            child: AchievementUnlockSequence(
              achievements: _pendingAchievements,
              onDone: () => setState(() => _pendingAchievements = []),
            ),
          ),
      ],
    );
  }
}

// ── Bottom nav sin labels ─────────────────────────────────────────────────────

class _StudentBottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;
  final String schoolId;
  final String memberId;

  const _StudentBottomNav({
    required this.selectedIndex,
    required this.onTap,
    required this.schoolId,
    required this.memberId,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    final unselected = Colors.grey.shade400;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(icon: Icons.school_outlined, selectedIcon: Icons.school, index: 0, selectedIndex: selectedIndex, color: primary, unselected: unselected, onTap: onTap),
              _NavItem(icon: Icons.leaderboard_outlined, selectedIcon: Icons.leaderboard, index: 1, selectedIndex: selectedIndex, color: primary, unselected: unselected, onTap: onTap),
              _NavItem(icon: Icons.groups_outlined, selectedIcon: Icons.groups, index: 2, selectedIndex: selectedIndex, color: primary, unselected: unselected, onTap: onTap),
              _PaymentNavItem(selectedIndex: selectedIndex, color: primary, unselected: unselected, onTap: onTap, schoolId: schoolId, memberId: memberId),
              _NavItem(icon: Icons.person_outline, selectedIcon: Icons.person, index: 4, selectedIndex: selectedIndex, color: primary, unselected: unselected, onTap: onTap),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData selectedIcon;
  final int index;
  final int selectedIndex;
  final Color color;
  final Color unselected;
  final ValueChanged<int> onTap;

  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.index,
    required this.selectedIndex,
    required this.color,
    required this.unselected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = index == selectedIndex;
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(
          isSelected ? selectedIcon : icon,
          color: isSelected ? color : unselected,
          size: 26,
        ),
      ),
    );
  }
}

class _PaymentNavItem extends StatelessWidget {
  final int selectedIndex;
  final Color color;
  final Color unselected;
  final ValueChanged<int> onTap;
  final String schoolId;
  final String memberId;

  const _PaymentNavItem({
    required this.selectedIndex,
    required this.color,
    required this.unselected,
    required this.onTap,
    required this.schoolId,
    required this.memberId,
  });

  @override
  Widget build(BuildContext context) {
    const index = 3;
    final isSelected = index == selectedIndex;
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('schools').doc(schoolId)
              .collection('members').doc(memberId)
              .collection('paymentReminders')
              .where('status', isEqualTo: 'pending')
              .limit(1)
              .snapshots(),
          builder: (context, snapshot) {
            final hasPending = snapshot.hasData && snapshot.data!.docs.isNotEmpty;
            return Badge(
              isLabelVisible: hasPending,
              child: Icon(
                isSelected ? Icons.payment : Icons.payment_outlined,
                color: isSelected ? color : unselected,
                size: 26,
              ),
            );
          },
        ),
      ),
    );
  }
}
