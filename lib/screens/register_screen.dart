import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:warrior_path/screens/verify_email_screen.dart';
import 'package:warrior_path/services/auth_service.dart';
import 'package:warrior_path/theme/AppColors.dart';
import 'package:warrior_path/widgets/CustomInputField.dart';
import 'package:warrior_path/widgets/CustomPasswordField.dart';
import 'package:warrior_path/widgets/PrimaryButton.dart';
import '../l10n/app_localizations.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  final AuthService _authService = AuthService();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _performRegistration() async {
    final l10n = AppLocalizations.of(context);
    if (_isLoading) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showErrorDialog(l10n.errorTitle, l10n.registrationErrorContent);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = await _authService.signUpWithEmailPassword(email, password);
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => VerifyEmailScreen(email: user.email ?? email),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      String msg;
      switch (e.code) {
        case 'email-already-in-use':
          msg = 'Ya existe una cuenta con ese correo.';
          break;
        case 'weak-password':
          msg = 'La contraseña es muy débil. Usá al menos 6 caracteres.';
          break;
        case 'invalid-email':
          msg = 'El correo ingresado no es válido.';
          break;
        default:
          msg = l10n.unexpectedError;
      }
      _showErrorDialog(l10n.registrationErrorTitle, msg);
    } catch (e) {
      _showErrorDialog(l10n.errorTitle, l10n.genericErrorContent(e.toString()));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showErrorDialog(String title, String content) {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.ok),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.backgroundGray,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            height: MediaQuery.of(context).size.height * 0.3,
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            decoration: const BoxDecoration(
              color: AppColors.primaryColor,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(50)),
            ),
            child: SafeArea(
              child: Stack(
                children: [
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ClipOval(
                          child: Image.asset(
                            'assets/logo/Logo.png',
                            height: 72,
                            width: 72,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Crear cuenta',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textWhite,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 0,
                    left: 0,
                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_back,
                        color: AppColors.textWhite,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
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
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 20),
                    Text(
                      'Ingresá tu correo y contraseña para empezar',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppColors.textLight,
                      ),
                    ),
                    const SizedBox(height: 32),
                    CustomInputField(
                      controller: _emailController,
                      labelText: l10n.emailLabel,
                      icon: Icons.email_outlined,
                    ),
                    const SizedBox(height: 16),
                    CustomPasswordField(controller: _passwordController),
                    const SizedBox(height: 32),
                    if (_isLoading)
                      const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.primaryColor,
                          ),
                        ),
                      )
                    else
                      PrimaryButton(
                        text: 'Crear cuenta',
                        onPressed: _performRegistration,
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
