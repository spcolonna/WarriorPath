import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:warrior_path/screens/student/application_sent_screen.dart';
import 'package:warrior_path/screens/student/student_dashboard_screen.dart';
import 'package:warrior_path/screens/teacher_dashboard_screen.dart';
import 'package:warrior_path/screens/wizard_profile_screen.dart';
import 'package:warrior_path/services/auth_service.dart';
import 'package:warrior_path/theme/AppColors.dart';
import 'package:warrior_path/widgets/CustomInputField.dart';
import 'package:warrior_path/widgets/CustomPasswordField.dart';
import 'package:warrior_path/widgets/PrimaryButton.dart';
import 'package:warrior_path/widgets/SecondaryButton.dart';

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

  // NUEVA FUNCIÓN CENTRALIZADA PARA NAVEGAR
  Future<void> _navigateAfterAuth(User user) async {
    final userProfileDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

    if (!mounted) return;

    if (!userProfileDoc.exists) {
      _showErrorDialog('Error de Perfil', 'No se pudo cargar tu perfil. Intenta de nuevo.');
      setState(() { _isLoading = false; });
      return;
    }

    final userData = userProfileDoc.data()!;
    final int wizardStep = userData['wizardStep'] ?? 0;

    // LÓGICA DEL GUARDIÁN MEJORADA
    if (wizardStep < 99) {
      // Si el wizard no está completo, lo mandamos al paso que corresponda.
      // (Aquí podríamos añadir lógica para ir a pasos intermedios, pero por ahora esto funciona)
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const WizardProfileScreen()),
      );
    } else {
      // El wizard ESTÁ COMPLETO. Ahora, ¿qué tipo de usuario es?
      final memberships = userData['activeMemberships'] as Map<String, dynamic>? ?? {};
      final pendingApplication = userData['pendingApplication'] as Map<String, dynamic>?;

      if (memberships.containsValue('maestro')) {
        // Si es maestro en alguna escuela, va al dashboard de profesor.
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const TeacherDashboardScreen()),
        );
      } else if (memberships.containsValue('alumno')) {
        // Si es alumno en alguna escuela, va al dashboard de estudiante.
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const StudentDashboardScreen()),
        );
      } else if (pendingApplication != null) {
        // Si no tiene membresías activas pero tiene una postulación pendiente,
        // lo enviamos a la pantalla de "solicitud enviada".
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => ApplicationSentScreen(schoolName: pendingApplication['schoolName'] ?? '')),
        );
      } else {
        // Caso de fallback: wizard completo pero sin rol.
        // Podría ser un usuario rechazado. Lo dejamos en la pantalla de bienvenida.
        _showErrorDialog('Acceso Denegado', 'No tienes un rol activo en ninguna escuela.');
        setState(() { _isLoading = false; });
      }
    }
  }


  Future<void> _performLogin() async {
    if (_isLoading) return;
    setState(() { _isLoading = true; });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // CAMBIO: Usamos la nueva función de navegación
      if (userCredential.user != null) {
        await _navigateAfterAuth(userCredential.user!);
      }

    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No se encontró un usuario con ese correo electrónico.';
          break;
        case 'wrong-password':
          errorMessage = 'La contraseña es incorrecta.';
          break;
        case 'invalid-credential':
          errorMessage = 'Las credenciales son incorrectas.';
          break;
        default:
          errorMessage = 'Ocurrió un error inesperado.';
      }
      _showErrorDialog('Error de Login', errorMessage);
    } catch (e) {
      _showErrorDialog('Error', 'Ocurrió un error: ${e.toString()}');
    } finally {
      if (mounted && _isLoading) { // Solo si aún está cargando
        setState(() { _isLoading = false; });
      }
    }
  }

  Future<void> _performRegistration() async {
    if (_isLoading) return;
    setState(() { _isLoading = true; });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      final userModel = await _authService.signUpWithEmailPassword(email, password);

      // CAMBIO: Usamos la nueva función de navegación
      if (userModel != null) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await _navigateAfterAuth(user);
        }
      } else {
        _showErrorDialog('Error de Registro', 'No se pudo completar el registro. El correo puede ya estar en uso o la contraseña es muy débil.');
      }
    } catch (e) {
      _showErrorDialog('Error', 'Ocurrió un error inesperado: ${e.toString()}');
    } finally {
      if (mounted && _isLoading) {
        setState(() { _isLoading = false; });
      }
    }
  }

  void _showErrorDialog(String title, String content) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: <Widget>[
          TextButton(
            child: const Text('Ok'),
            onPressed: () {
              Navigator.of(ctx).pop();
            },
          )
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
    // El resto de tu widget de UI no cambia
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
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(50),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ClipOval(
                  child: Image.asset(
                    'assets/logo/Logo.png',
                    height: 90, // Define la altura
                    width: 90,  // Define el ancho, igual a la altura para un círculo perfecto
                    fit: BoxFit.cover, // Asegura que la imagen cubra el círculo
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Warrior Path',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 42.0,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textWhite,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    const Text(
                      'Crea y participa en rifas fácilmente',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18, color: AppColors.textLight),
                    ),
                    const SizedBox(height: 32.0),
                    CustomInputField(
                      controller: _emailController,
                      labelText: 'Correo Electrónico',
                      icon: Icons.email_outlined,
                    ),
                    const SizedBox(height: 16.0),
                    CustomPasswordField(
                      controller: _passwordController,
                    ),
                    const SizedBox(height: 32.0),
                    if (_isLoading)
                      const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.secondaryColor),
                      )
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SecondaryButton(
                            text: 'Iniciar Sesión',
                            onPressed: _performLogin,
                          ),
                          const SizedBox(height: 16.0),
                          PrimaryButton(
                            text: 'Crear Cuenta',
                            onPressed: _performRegistration,
                          ),
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
