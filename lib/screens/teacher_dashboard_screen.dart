import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:warrior_path/providers/theme_provider.dart';
import 'package:warrior_path/screens/dashboard/tabs/home_tab_screen.dart';
import 'package:warrior_path/screens/dashboard/tabs/management_tab_screen.dart';
import 'package:warrior_path/screens/dashboard/tabs/profile_tab_screen.dart';
import 'package:warrior_path/screens/dashboard/tabs/students_tab_screen.dart';

class TeacherDashboardScreen extends StatefulWidget {
  const TeacherDashboardScreen({Key? key}) : super(key: key);

  @override
  State<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends State<TeacherDashboardScreen> {
  int _selectedIndex = 0;
  int _studentSubTabIndex = 0; // Estado para recordar la sub-pestaña de alumnos
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

      // Cargar el tema de la escuela usando el Provider
      // listen: false porque solo lo hacemos una vez al cargar
      Provider.of<ThemeProvider>(context, listen: false).loadThemeFromSchool(schoolId);

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

  // Función actualizada que puede recibir un subTabIndex
  void _onItemTapped(int index, {int? subTabIndex}) {
    setState(() {
      _selectedIndex = index;
      _studentSubTabIndex = (index == 1 && subTabIndex != null) ? subTabIndex : 0;
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

    // La lista de pantallas se construye aquí para pasar los datos correctos
    final List<Widget> widgetOptions = <Widget>[
      HomeTabScreen(
        schoolId: _schoolId!,
        onNavigateToTab: (index, {subTabIndex}) => _onItemTapped(index, subTabIndex: subTabIndex),
      ),
      StudentsTabScreen(
        schoolId: _schoolId!,
        initialTabIndex: _studentSubTabIndex,
      ),
      ManagementTabScreen(schoolId: _schoolId!),
      const ProfileTabScreen(),
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
        onTap: (index) => _onItemTapped(index), // El tap normal no necesita subTabIndex
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
