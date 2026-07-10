import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:warrior_path/providers/session_provider.dart';
import 'package:warrior_path/screens/parent/add_child_screen.dart';
import 'package:warrior_path/screens/parent/guardian_dashboard_screen.dart';
import 'package:warrior_path/screens/role_selector_screen.dart';
import 'package:warrior_path/screens/student/pending_progress_screen.dart';
import 'package:warrior_path/screens/student/school_search_screen.dart';
import 'package:warrior_path/screens/student/student_dashboard_screen.dart';
import 'package:warrior_path/screens/teacher_dashboard_screen.dart';
import 'package:warrior_path/screens/verify_email_screen.dart';
import 'package:warrior_path/screens/wizard_create_school_screen.dart';
import 'package:warrior_path/screens/wizard_discipline_hub_screen.dart';
import 'package:warrior_path/screens/wizard_profile_screen.dart';

/// Rutea al usuario luego de autenticarse (login email/password, verificación
/// de mail o login social). Es la única fuente de verdad del ruteo post-auth.
///
/// ANTI-SPAM: el documento `users/{uid}` recién se crea acá, y solo si el mail
/// está verificado. Los usuarios existentes ya tienen su documento, así que
/// nunca se los bloquea. Un usuario nuevo sin verificar es enviado a
/// [VerifyEmailScreen] sin escribir nada en la base.
Future<void> navigateAfterAuth(BuildContext context, User user) async {
  final userProfileDoc = await FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .get();

  if (!context.mounted) return;

  if (!userProfileDoc.exists) {
    // Gate anti-spam: no crear el documento hasta que el mail esté verificado.
    if (!user.emailVerified) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => VerifyEmailScreen(email: user.email ?? ''),
        ),
      );
      return;
    }

    final newUserProfile = {
      'uid': user.uid,
      'email': user.email,
      'wizardStep': 0,
      'createdAt': FieldValue.serverTimestamp(),
      'displayName': user.displayName ?? '',
      'photoUrl': user.photoURL ?? '',
    };
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .set(newUserProfile);
    if (!context.mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const WizardProfileScreen()),
    );
    return;
  }

  final userData = userProfileDoc.data()!;
  final int wizardStep = userData['wizardStep'] ?? 0;
  final String? userRole = userData['role'];

  if (wizardStep < 99) {
    switch (wizardStep) {
      case 0:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const WizardProfileScreen()),
        );
        break;
      case 1:
        switch (userRole) {
          case 'student':
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) =>
                    const SchoolSearchScreen(isFromWizard: true),
              ),
            );
            break;
          case 'parent':
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const AddChildScreen()),
            );
            break;
          case 'teacher':
          case 'both':
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => const WizardCreateSchoolScreen(),
              ),
            );
            break;
          default:
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => const WizardProfileScreen(),
              ),
            );
        }
        break;

      case 2:
      case 3:
      case 4:
      case 5:
        final memberships =
            userData['activeMemberships'] as Map<String, dynamic>? ?? {};
        if (memberships.isNotEmpty) {
          final schoolId = memberships.keys.first;
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) =>
                  WizardDisciplineHubScreen(schoolId: schoolId),
            ),
          );
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const WizardCreateSchoolScreen(),
            ),
          );
        }
        break;

      default:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const WizardProfileScreen()),
        );
    }
  } else {
    final memberships =
        userData['activeMemberships'] as Map<String, dynamic>? ?? {};

    if (userRole == 'parent' && memberships.isEmpty) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const GuardianDashboardScreen()),
      );
    } else if (memberships.isNotEmpty) {
      if (memberships.length == 1 &&
          (userRole == 'student' || userRole == 'teacher')) {
        final schoolId = memberships.keys.first;
        final role = memberships.values.first;
        Provider.of<SessionProvider>(context, listen: false)
            .setFullActiveSession(schoolId, role, user.uid, authUid: user.uid);
        Widget destination = (role == 'maestro')
            ? const TeacherDashboardScreen()
            : const StudentDashboardScreen();
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => destination),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const RoleSelectorScreen()),
        );
      }
    } else {
      final pendingApplications =
          userData['pendingApplications'] as Map<String, dynamic>?;
      if (pendingApplications != null && pendingApplications.isNotEmpty) {
        final firstApp =
            pendingApplications.values.first as Map<String, dynamic>;
        final schoolName = firstApp['schoolName'] as String? ?? '';
        final applicationDate =
            (firstApp['applicationDate'] as Timestamp?)?.toDate();
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => PendingProgressScreen(
              schoolName: schoolName,
              applicationDate: applicationDate,
            ),
          ),
        );
      } else {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const SchoolSearchScreen()),
        );
      }
    }
  }
}
