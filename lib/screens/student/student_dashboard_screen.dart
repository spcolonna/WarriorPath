import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:confetti/confetti.dart';
import 'package:warrior_path/providers/session_provider.dart';
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
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 4));

    // Usamos esto para ejecutar una función después de que la pantalla se haya construido
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkUnseenPromotion();
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  // Revisa si el alumno tiene una promoción que no ha visto para mostrar la celebración
  Future<void> _checkUnseenPromotion() async {
    // listen: false porque solo necesitamos leer el valor una vez aquí
    final session = Provider.of<SessionProvider>(context, listen: false);
    final schoolId = session.activeSchoolId;
    final memberId = FirebaseAuth.instance.currentUser?.uid;

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

  // Muestra el diálogo de felicitación y la animación de confeti
  void _showPromotionCelebration(String schoolId, String newLevelId) async {
    final memberId = FirebaseAuth.instance.currentUser?.uid;
    if (memberId == null) return;

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
    // Obtenemos la sesión activa desde el Provider. La pantalla ahora depende de esto.
    final session = Provider.of<SessionProvider>(context);
    final schoolId = session.activeSchoolId;
    final memberId = FirebaseAuth.instance.currentUser?.uid;

    // Si por alguna razón no hay sesión, mostramos un estado de error seguro.
    if (schoolId == null || memberId == null) {
      return const Scaffold(body: Center(child: Text('Error: No hay una sesión activa.')));
    }

    // Definimos las pantallas que irán en las pestañas, pasándoles los IDs necesarios
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
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(icon: Icon(Icons.school), label: 'Mi Escuela'),
              BottomNavigationBarItem(icon: Icon(Icons.leaderboard), label: 'Mi Progreso'),
              BottomNavigationBarItem(icon: Icon(Icons.groups), label: 'Comunidad'),
              BottomNavigationBarItem(icon: Icon(Icons.payment), label: 'Mis Pagos'),
              BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Mi Perfil'),
            ],
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            type: BottomNavigationBarType.fixed, // Asegura que se vean todas las pestañas
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
