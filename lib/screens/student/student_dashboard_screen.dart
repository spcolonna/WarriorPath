import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:confetti/confetti.dart';
import 'package:warrior_path/providers/session_provider.dart';
import 'package:warrior_path/screens/student/tabs/community_tab_screen.dart';
import 'package:warrior_path/screens/student/tabs/payments_tab_screen.dart';
import 'package:warrior_path/screens/student/tabs/profile_tab_screen.dart';
import 'package:warrior_path/screens/student/tabs/progress_tab_screen.dart';
import 'package:warrior_path/screens/student/tabs/school_info_tab_screen.dart';

import '../../l10n/app_localizations.dart';

class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({super.key});

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

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 4));

    WidgetsBinding.instance.addPostFrameCallback((_) {
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
      ProgressTabScreen(schoolId: schoolId, memberId: memberId),
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
          bottomNavigationBar: BottomNavigationBar(
            items: <BottomNavigationBarItem>[
              BottomNavigationBarItem(icon: const Icon(Icons.school), label: l10n.mySchool),
              BottomNavigationBarItem(icon: const Icon(Icons.leaderboard), label: l10n.myProgress),
              BottomNavigationBarItem(icon: const Icon(Icons.groups), label: l10n.schoolCommunity),
              BottomNavigationBarItem(
                label: l10n.myPayments,
                icon: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('schools').doc(schoolId)
                      .collection('members').doc(memberId)
                      .collection('paymentReminders')
                      .where('status', isEqualTo: 'pending')
                      .limit(1)
                      .snapshots(),
                  builder: (context, snapshot) {
                    final bool hasPendingPayments = snapshot.hasData && snapshot.data!.docs.isNotEmpty;
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        const Icon(Icons.payment),
                        if (hasPendingPayments)
                          Positioned(
                            top: -4,
                            right: -6,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
              BottomNavigationBarItem(icon: const Icon(Icons.person), label: l10n.myProfile),
            ],
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            type: BottomNavigationBarType.fixed,
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
      ],
    );
  }
}
