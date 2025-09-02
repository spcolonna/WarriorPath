import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
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
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStudentData();
  }

  // Carga el ID de la escuela a la que pertenece el alumno
  Future<void> _loadStudentData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Usuario no autenticado');

      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final memberships = userDoc.data()?['activeMemberships'] as Map<String, dynamic>? ?? {};

      final schoolId = memberships.keys.firstWhere((k) => memberships[k] == 'alumno', orElse: () => '');

      if (schoolId.isEmpty) throw Exception('No perteneces a ninguna escuela.');

      if (mounted) {
        setState(() {
          _schoolId = schoolId;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_error != null) {
      return Scaffold(body: Center(child: Text('Error: $_error')));
    }

    final List<Widget> widgetOptions = <Widget>[
      SchoolInfoTabScreen(schoolId: _schoolId!),
      ProgressTabScreen(schoolId: _schoolId!),
      const StudentProfileTabScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: widgetOptions,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.school), label: 'Mi Escuela'),
          BottomNavigationBarItem(icon: Icon(Icons.leaderboard), label: 'Mi Progreso'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Mi Perfil'),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
