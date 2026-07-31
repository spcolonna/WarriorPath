import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:warrior_path/screens/WelcomeScreen.dart';
import 'package:warrior_path/screens/student/school_search_screen.dart';
import 'package:warrior_path/screens/wizard_create_school_screen.dart';
import 'package:warrior_path/theme/AppColors.dart';

import '../../l10n/app_localizations.dart';

/// Lo que ve un alumno al que su maestro dio de baja.
///
/// El punto de esta pantalla es que el alumno NO quede en un limbo: se le
/// explica qué pasó, y se le ofrecen las dos salidas posibles (buscar otra
/// escuela o crear la suya). No puede re-postularse solo a la escuela que lo
/// dio de baja — para eso el maestro tiene que reactivarlo.
class InactivatedScreen extends StatelessWidget {
  final String schoolName;

  const InactivatedScreen({super.key, required this.schoolName});

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const WelcomeScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.backgroundGray,
      appBar: AppBar(
        title: Text(l10n.inactivatedTitle),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: l10n.logOut,
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            const Icon(
              Icons.pause_circle_outline,
              size: 72,
              color: AppColors.primaryColor,
            ),
            const SizedBox(height: 24),
            Text(
              l10n.inactivatedTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.inactivatedBody(schoolName),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: AppColors.textDark),
            ),
            const SizedBox(height: 32),
            Text(
              l10n.inactivatedHint,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.search),
              label: Text(l10n.searchAnotherSchool),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const SchoolSearchScreen(),
                ),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.add_business_outlined),
              label: Text(l10n.createMySchool),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const WizardCreateSchoolScreen(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
