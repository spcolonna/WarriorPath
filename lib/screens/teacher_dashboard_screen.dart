import 'package:flutter/material.dart';
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

  // Lista de las pantallas que se mostrarán en cada pestaña
  static const List<Widget> _widgetOptions = <Widget>[
    HomeTabScreen(),
    StudentsTabScreen(),
    ManagementTabScreen(),
    ProfileTabScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _widgetOptions,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.groups),
            label: 'Alumnos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Gestión',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).primaryColor, // Usa el color primario de tu tema
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed, // Asegura que todos los items sean visibles
      ),
    );
  }
}
