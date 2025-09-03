import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:warrior_path/providers/session_provider.dart';
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

  // --- CAMBIO CLAVE AQUÍ ---
  // Reemplazamos 'const' por 'final' para permitir que la lista contenga
  // widgets que no son necesariamente constantes en tiempo de compilación.
  static final List<Widget> _widgetOptions = <Widget>[
    const HomeTabScreen(),
    const StudentsTabScreen(),
    const ManagementTabScreen(),
    const ProfileTabScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
    // Cargamos el tema de la escuela activa al iniciar el dashboard
    final session = Provider.of<SessionProvider>(context, listen: false);
    if (session.activeSchoolId != null) {
      Provider.of<ThemeProvider>(context, listen: false).loadThemeFromSchool(session.activeSchoolId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = Provider.of<SessionProvider>(context);
    if (session.activeSchoolId == null) {
      return const Scaffold(body: Center(child: Text('Error: No hay una sesión activa.')));
    }

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _widgetOptions,
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
