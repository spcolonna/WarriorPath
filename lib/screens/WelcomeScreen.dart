import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:warrior_path/screens/parent/guardian_dashboard_screen.dart';
import 'package:warrior_path/screens/role_selector_screen.dart';
import 'package:warrior_path/screens/student/application_sent_screen.dart';
import 'package:warrior_path/screens/student/school_search_screen.dart';
import 'package:warrior_path/screens/student/student_dashboard_screen.dart';
import 'package:warrior_path/screens/teacher_dashboard_screen.dart';
import 'package:warrior_path/screens/wizard_profile_screen.dart';
import 'package:warrior_path/services/auth_service.dart';
import 'package:warrior_path/theme/AppColors.dart';
import 'package:warrior_path/widgets/CustomInputField.dart';
import 'package:warrior_path/widgets/CustomPasswordField.dart';
import 'package:warrior_path/widgets/PrimaryButton.dart';
import 'package:warrior_path/widgets/SecondaryButton.dart';

import '../l10n/app_localizations.dart';
import '../providers/session_provider.dart';
import '../widgets/language_switcher.dart';
import 'forgot_password_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  final AuthService _authService = AuthService();

  Future<void> _navigateAfterAuth(User user) async {
    final l10n = AppLocalizations.of(context)!;
    final userProfileDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    if (!mounted) return;
    if (!userProfileDoc.exists) {
      final newUserProfile = {
        'uid': user.uid, 'email': user.email, 'wizardStep': 0, 'createdAt': FieldValue.serverTimestamp(), 'displayName': user.displayName ?? '', 'photoUrl': user.photoURL ?? '',
      };
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set(newUserProfile);
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => const WizardProfileScreen()));
      return;
    }
    final userData = userProfileDoc.data()!;
    final int wizardStep = userData['wizardStep'] ?? 0;
    if (wizardStep < 99) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => const WizardProfileScreen()));
    } else {
      final memberships = userData['activeMemberships'] as Map<String, dynamic>? ?? {};
      // Leemos el rol principal que el usuario eligió en el wizard
      final mainRole = userData['role'] as String?;

      // Caso 1: El usuario es principalmente un tutor
      if (mainRole == 'parent') {
        // Si su rol es 'parent', SIEMPRE va a su panel de tutor.
        // Aquí es donde verá la lista de sus hijos (o una lista vacía si aún no ha añadido ninguno).
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => const GuardianDashboardScreen()));

        // Caso 2: El usuario es alumno/maestro y ya tiene membresías activas
      } else if (memberships.isNotEmpty) {
        if (memberships.length == 1) {
          // Entra directo a su único rol
          final schoolId = memberships.keys.first;
          final role = memberships.values.first;
          Provider.of<SessionProvider>(context, listen: false).setFullActiveSession(schoolId, role, user.uid);
          Widget destination = (role == 'maestro') ? const TeacherDashboardScreen() : const StudentDashboardScreen();
          Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => destination));
        } else {
          // Tiene múltiples roles, va al selector
          Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => const RoleSelectorScreen()));
        }

        // Caso 3: El usuario es alumno/maestro pero AÚN NO tiene membresías
      } else {
        final pendingApplication = userData['pendingApplications'] as Map<String, dynamic>?;
        if (pendingApplication != null) {
          // Tiene una postulación pendiente
          Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => ApplicationSentScreen(schoolName: pendingApplication['schoolName'] ?? '')));
        } else {
          // Es un alumno/maestro sin escuela, lo mandamos a buscar una
          Navigator.of(context).push(MaterialPageRoute(builder: (context) => const SchoolSearchScreen()));
        }
      }
    }
  }

  Future<void> _performLogin() async {
    final l10n = AppLocalizations.of(context)!;
    if (_isLoading) return;
    setState(() { _isLoading = true; });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);
      if (userCredential.user != null) {
        await _navigateAfterAuth(userCredential.user!);
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'user-not-found': errorMessage = l10n.loginErrorUserNotFound; break;
        case 'wrong-password': errorMessage = l10n.loginErrorWrongPassword; break;
        case 'invalid-credential': errorMessage = l10n.loginErrorInvalidCredential; break;
        default: errorMessage = l10n.unexpectedError;
      }
      _showErrorDialog(l10n.loginErrorTitle, errorMessage);
    } catch (e) {
      _showErrorDialog(l10n.errorTitle, l10n.genericErrorContent(e.toString()));
    } finally {
      if (mounted && _isLoading) { setState(() { _isLoading = false; }); }
    }
  }

  Future<void> _performRegistration() async {
    final l10n = AppLocalizations.of(context)!;
    if (_isLoading) return;
    setState(() { _isLoading = true; });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      final userModel = await _authService.signUpWithEmailPassword(email, password);
      if (userModel != null) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await _navigateAfterAuth(user);
        }
      } else {
        _showErrorDialog(l10n.registrationErrorTitle, l10n.registrationErrorContent);
      }
    } catch (e) {
      _showErrorDialog(l10n.errorTitle, l10n.genericErrorContent(e.toString()));
    } finally {
      if (mounted && _isLoading) { setState(() { _isLoading = false; }); }
    }
  }

  void _showErrorDialog(String title, String content) {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: <Widget>[
        TextButton(child: Text(l10n.ok), onPressed: () { Navigator.of(ctx).pop(); })
      ],
    ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Obtenemos la instancia de l10n para usar en el build
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.backgroundGray,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            height: MediaQuery.of(context).size.height * 0.35,
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            decoration: const BoxDecoration(
              color: AppColors.primaryColor,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(50)),
            ),
            child: SafeArea( // 1. Envolvemos el Stack con SafeArea
              child: Stack(
                children: [
                  // La columna con el logo y el título no cambia...
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Center(
                        child: ClipOval(
                          child: Image.asset('assets/logo/Logo.png', height: 90, width: 90, fit: BoxFit.cover),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.appName,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 42.0, fontWeight: FontWeight.bold, color: AppColors.textWhite),
                      ),
                    ],
                  ),
                  Positioned(
                    // 2. Ahora podemos usar top: 0 porque es relativo al ÁREA SEGURA, no a la pantalla.
                    top: 0,
                    right: 12, // Un poco de espacio desde el borde
                    child: const LanguageSwitcher(),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    Text(
                      l10n.appSlogan,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 18, color: AppColors.textLight),
                    ),
                    const SizedBox(height: 32.0),
                    CustomInputField(
                      controller: _emailController,
                      labelText: l10n.emailLabel,
                      icon: Icons.email_outlined,
                    ),
                    const SizedBox(height: 16.0),
                    CustomPasswordField(
                      controller: _passwordController,
                    ),
                    const SizedBox(height: 32.0),
                    if (_isLoading)
                      const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppColors.secondaryColor))
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SecondaryButton(text: l10n.loginButton, onPressed: _performLogin),
                          const SizedBox(height: 16.0),
                          PrimaryButton(text: l10n.createAccountButton, onPressed: _performRegistration),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).push(MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()));
                            },
                            child: Text(l10n.forgotPasswordLink),
                          )
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
