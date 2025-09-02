import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:warrior_path/screens/dashboard/tabs/home_tab_screen.dart';
import 'package:warrior_path/screens/dashboard/tabs/management_tab_screen.dart';
import 'package:warrior_path/screens/dashboard/tabs/profile_tab_screen.dart';
import 'package:warrior_path/screens/dashboard/tabs/students_tab_screen.dart';

import '../providers/theme_provider.dart';

class TeacherDashboardScreen extends StatefulWidget {
  const TeacherDashboardScreen({Key? key}) : super(key: key);

  @override
  State<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends State<TeacherDashboardScreen> {
  int _selectedIndex = 0;
  String? _schoolId;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSchoolData();
  }

  Future<void> _loadSchoolData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Usuario no autenticado');

      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final memberships = userDoc.data()?['activeMemberships'] as Map<String, dynamic>? ?? {};

      final schoolId = memberships.keys.firstWhere((k) => memberships[k] == 'maestro', orElse: () => '');

      if (schoolId.isEmpty) throw Exception('No se encontró una escuela para gestionar.');

      if (schoolId.isNotEmpty) {
        Provider.of<ThemeProvider>(context, listen: false).loadThemeFromSchool(schoolId);
      }

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

    // Una vez que tenemos el schoolId, construimos la lista de pantallas
    final List<Widget> widgetOptions = <Widget>[
      HomeTabScreen(schoolId: _schoolId!),
      StudentsTabScreen(schoolId: _schoolId!),
      ManagementTabScreen(schoolId: _schoolId!),
      const ProfileTabScreen(), // El perfil no necesita el schoolId
    ];

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: widgetOptions,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.groups), label: 'Alumnos'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Gestión'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
