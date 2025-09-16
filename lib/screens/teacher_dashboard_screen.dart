import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:warrior_path/providers/session_provider.dart';
import 'package:warrior_path/providers/theme_provider.dart';
import 'package:warrior_path/screens/subscription_lapsed_screen.dart';

import 'dashboard/tabs/home_tab_screen.dart';
import 'dashboard/tabs/management_tab_screen.dart';
import 'dashboard/tabs/profile_tab_screen.dart';
import 'dashboard/tabs/students_tab_screen.dart';


class TeacherDashboardScreen extends StatefulWidget {
  const TeacherDashboardScreen({Key? key}) : super(key: key);

  @override
  State<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends State<TeacherDashboardScreen> {
  int _selectedIndex = 0;

  bool _isCheckingSubscription = true;
  bool _isSubscriptionActive = false;

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
    final session = Provider.of<SessionProvider>(context, listen: false);
    if (session.activeSchoolId != null) {
      Provider.of<ThemeProvider>(context, listen: false).loadThemeFromSchool(session.activeSchoolId!);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkSubscriptionStatus();
    });
  }

  Future<void> _checkSubscriptionStatus() async {
    if (!mounted) return;
    setState(() => _isCheckingSubscription = true);

    final session = Provider.of<SessionProvider>(context, listen: false);
    final schoolId = session.activeSchoolId;

    if (schoolId == null) {
      if (mounted) setState(() => _isSubscriptionActive = false);
      return;
    }

    try {
      final schoolDoc = await FirebaseFirestore.instance.collection('schools').doc(schoolId).get();
      if (!schoolDoc.exists) {
        if (mounted) setState(() => _isSubscriptionActive = false);
        return;
      }

      final data = schoolDoc.data();
      final subscriptionData = data?['subscription'] as Map<String, dynamic>?;
      final expiryDateTimestamp = subscriptionData?['expiryDate'] as Timestamp?;

      if (expiryDateTimestamp == null) {
        if (mounted) setState(() => _isSubscriptionActive = false);
      } else {
        final expiryDate = expiryDateTimestamp.toDate();
        if (expiryDate.isAfter(DateTime.now())) {
          if (mounted) setState(() => _isSubscriptionActive = true);
        } else {
          if (mounted) setState(() => _isSubscriptionActive = false);
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isSubscriptionActive = false);
    } finally {
      if (mounted) setState(() => _isCheckingSubscription = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    if (_isCheckingSubscription) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!_isSubscriptionActive) {
      return const SubscriptionLapsedScreen();
    }

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
