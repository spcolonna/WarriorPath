import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:warrior_path/screens/student/tabs/community_tab_screen.dart';
import 'package:warrior_path/screens/student/tabs/payments_tab_screen.dart';
import 'package:warrior_path/screens/student/tabs/profile_tab_screen.dart';
import 'package:warrior_path/screens/student/tabs/progress_tab_screen.dart';
import 'package:warrior_path/screens/student/tabs/school_info_tab_screen.dart';

class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({Key? key}) : super(key: key);

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  int _selectedIndex = 0;
  String? _schoolId;
  String? _memberId;
  bool _isLoading = true;
  String? _error;
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 4));
    _loadStudentData();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _loadStudentData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Usuario no autenticado');
      _memberId = user.uid;

      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final memberships = userDoc.data()?['activeMemberships'] as Map<String, dynamic>? ?? {};
      final schoolId = memberships.keys.firstWhere(
            (k) => memberships[k] == 'alumno' || memberships[k] == 'instructor',
        orElse: () => '',
      );

      if (schoolId.isEmpty) throw Exception('No perteneces a ninguna escuela.');

      // Chequeamos si hay una promoción sin ver
      final memberDoc = await FirebaseFirestore.instance.collection('schools').doc(schoolId).collection('members').doc(_memberId).get();
      final hasUnseenPromotion = memberDoc.data()?['hasUnseenPromotion'] ?? false;

      if (hasUnseenPromotion) {
        // Usamos addPostFrameCallback para mostrar el diálogo después de que la pantalla se construya
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showPromotionCelebration(schoolId, memberDoc.data()?['currentLevelId']);
        });
      }

      if (mounted) {
        setState(() {
          _schoolId = schoolId;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  void _showPromotionCelebration(String schoolId, String newLevelId) async {
    // Obtenemos el nombre del nuevo nivel
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

    // Inmediatamente después, limpiamos la bandera para que no se muestre de nuevo
    await FirebaseFirestore.instance.collection('schools').doc(schoolId).collection('members').doc(_memberId).update({
      'hasUnseenPromotion': false,
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  @override
  Widget build(BuildContext context) {
    final List<Widget> widgetOptions = _isLoading || _error != null
        ? []
        : <Widget>[
      SchoolInfoTabScreen(schoolId: _schoolId!),
      ProgressTabScreen(schoolId: _schoolId!, memberId: _memberId!),
      CommunityTabScreen(schoolId: _schoolId!),
      PaymentsTabScreen(schoolId: _schoolId!, memberId: _memberId!),
      StudentProfileTabScreen(memberId: _memberId!),
    ];

    return Stack(
      alignment: Alignment.topCenter,
      children: [
        Scaffold(
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(child: Text('Error: $_error'))
              : IndexedStack(
            index: _selectedIndex,
            children: widgetOptions, // Usamos la nueva lista
          ),
          bottomNavigationBar: _isLoading || _error != null
              ? null
              : BottomNavigationBar(
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(icon: Icon(Icons.school), label: 'Mi Escuela'),
              BottomNavigationBarItem(icon: Icon(Icons.leaderboard), label: 'Mi Progreso'),
              BottomNavigationBarItem(icon: Icon(Icons.groups), label: 'Comunidad'),
              BottomNavigationBarItem(icon: Icon(Icons.payment), label: 'Mis Pagos'),
              BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Mi Perfil'),
            ],
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            type: BottomNavigationBarType.fixed, // Importante para que se vean +3 items
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
