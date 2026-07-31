import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:warrior_path/constants/school_roles.dart';
import 'package:warrior_path/providers/session_provider.dart';
import 'package:warrior_path/providers/theme_provider.dart';
import 'package:warrior_path/screens/school_pending_validation_screen.dart';

import '../l10n/app_localizations.dart';
import 'dashboard/tabs/home_tab_screen.dart';
import 'dashboard/tabs/management_tab_screen.dart';
import 'dashboard/tabs/profile_tab_screen.dart';
import 'dashboard/tabs/students_tab_screen.dart';

class TeacherDashboardScreen extends StatefulWidget {
  /// Pestaña en la que abrir: la usan los deep links de notificaciones para
  /// llevar al maestro directo a donde pasó algo (p. ej. Alumnos).
  final int initialTabIndex;

  const TeacherDashboardScreen({super.key, this.initialTabIndex = 0});

  @override
  State<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends State<TeacherDashboardScreen> {
  late AppLocalizations l10n;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    l10n = AppLocalizations.of(context);
  }

  int _selectedIndex = 0;

  bool _isCheckingValidation = true;
  bool _isSchoolValidated = false;

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
    _selectedIndex = widget.initialTabIndex;
    final session = Provider.of<SessionProvider>(context, listen: false);
    if (session.activeSchoolId != null) {
      Provider.of<ThemeProvider>(
        context,
        listen: false,
      ).loadThemeFromSchool(session.activeSchoolId!);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkValidationStatus();
    });
  }

  Future<void> _checkValidationStatus() async {
    if (!mounted) return;
    setState(() => _isCheckingValidation = true);

    final session = Provider.of<SessionProvider>(context, listen: false);
    final schoolId = session.activeSchoolId;

    if (schoolId == null) {
      if (mounted) setState(() => _isSchoolValidated = false);
      return;
    }

    try {
      final schoolDoc = await FirebaseFirestore.instance
          .collection('schools')
          .doc(schoolId)
          .get();
      if (!schoolDoc.exists) {
        if (mounted) setState(() => _isSchoolValidated = false);
        return;
      }

      // Acceso concedido si la escuela está validada manualmente (isValidated)
      // O si todavía tiene trial vigente (subscription.expiryDate). Así las
      // escuelas existentes siguen funcionando sin necesitar el campo nuevo.
      final data = schoolDoc.data();
      final isValidated = data?['isValidated'] == true;
      final subscriptionData =
          data?['subscription'] as Map<String, dynamic>?;
      final expiryTimestamp =
          subscriptionData?['expiryDate'] as Timestamp?;
      final trialActive = expiryTimestamp != null &&
          expiryTimestamp.toDate().isAfter(DateTime.now());
      if (mounted) setState(() => _isSchoolValidated = isValidated || trialActive);
    } catch (e) {
      if (mounted) setState(() => _isSchoolValidated = false);
    } finally {
      if (mounted) setState(() => _isCheckingValidation = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingValidation) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!_isSchoolValidated) {
      return const SchoolPendingValidationScreen();
    }

    final session = Provider.of<SessionProvider>(context);
    if (session.activeSchoolId == null) {
      return const Scaffold(
        body: Center(child: Text('Error: No hay una sesión activa.')),
      );
    }

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _widgetOptions),
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: l10n.home),
          BottomNavigationBarItem(
            icon: _PendingBadge(
              schoolId: session.activeSchoolId!,
              child: const Icon(Icons.groups),
            ),
            label: l10n.students,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: l10n.managment,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: l10n.profile,
          ),
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

/// Punto rojo sobre el ícono de Alumnos cuando hay solicitudes sin responder.
///
/// Es la señal pasiva que respalda al push: si la notificación no llegó (o el
/// maestro la descartó), la solicitud igual se ve al abrir la app.
class _PendingBadge extends StatelessWidget {
  final String schoolId;
  final Widget child;

  const _PendingBadge({required this.schoolId, required this.child});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('schools')
          .doc(schoolId)
          .collection('members')
          .where('status', isEqualTo: MemberStatus.pending)
          .snapshots(),
      builder: (context, snapshot) {
        final count = snapshot.data?.docs.length ?? 0;
        if (count == 0) return child;

        return Badge(
          label: Text('$count'),
          backgroundColor: Colors.red,
          child: child,
        );
      },
    );
  }
}
