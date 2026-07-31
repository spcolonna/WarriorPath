import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:warrior_path/screens/register_screen.dart';
import 'package:warrior_path/services/auth_service.dart';
import 'package:warrior_path/services/post_auth_navigator.dart';
import 'package:warrior_path/theme/AppColors.dart';
import 'package:warrior_path/widgets/CustomInputField.dart';
import 'package:warrior_path/widgets/CustomPasswordField.dart';
import 'package:warrior_path/widgets/PrimaryButton.dart';
import 'package:warrior_path/widgets/SecondaryButton.dart';
import '../l10n/app_localizations.dart';
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
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  Future<void> _navigateAfterAuth(User user) =>
      navigateAfterAuth(context, user);

  Future<void> _performLogin() async {
    final l10n = AppLocalizations.of(context);
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      final userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);
      if (userCredential.user != null) {
        await _navigateAfterAuth(userCredential.user!);
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = l10n.loginErrorUserNotFound;
          break;
        case 'wrong-password':
          errorMessage = l10n.loginErrorWrongPassword;
          break;
        case 'invalid-credential':
          errorMessage = l10n.loginErrorInvalidCredential;
          break;
        default:
          errorMessage = l10n.unexpectedError;
      }
      _showErrorDialog(l10n.loginErrorTitle, errorMessage);
    } catch (e) {
      _showErrorDialog(l10n.errorTitle, l10n.genericErrorContent(e.toString()));
    } finally {
      if (mounted && _isLoading) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleSocialLogin(Future<User?> Function() signIn) async {
    final l10n = AppLocalizations.of(context);
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      final user = await signIn();
      if (user != null && mounted) {
        await _navigateAfterAuth(user);
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog(
          l10n.errorTitle,
          l10n.genericErrorContent(e.toString()),
        );
      }
    } finally {
      if (mounted && _isLoading) {
        setState(() => _isLoading = false);
      }
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
        actions: <Widget>[
          TextButton(
            child: Text(l10n.ok),
            onPressed: () {
              Navigator.of(ctx).pop();
            },
          ),
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
    final l10n = AppLocalizations.of(context);

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
            child: SafeArea(
              // 1. Envolvemos el Stack con SafeArea
              child: Stack(
                children: [
                  // La columna con el logo y el título no cambia...
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Center(
                        child: ClipOval(
                          child: Image.asset(
                            'assets/logo/Logo.png',
                            height: 90,
                            width: 90,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.appName,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 42.0,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textWhite,
                        ),
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
                      style: const TextStyle(
                        fontSize: 18,
                        color: AppColors.textLight,
                      ),
                    ),
                    const SizedBox(height: 32.0),
                    if (_isLoading)
                      const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.secondaryColor,
                        ),
                      )
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Google y Apple van PRIMERO: es la forma más rápida
                          // de entrar y, abajo del todo, los usuarios nuevos ni
                          // se enteraban de que existía.
                          _SocialButton(
                            label: l10n.continueWithGoogle,
                            icon: Icons.g_mobiledata,
                            iconColor: const Color(0xFF4285F4),
                            onPressed: () =>
                                _handleSocialLogin(_authService.signInWithGoogle),
                          ),
                          if (Platform.isIOS) ...[
                            const SizedBox(height: 12.0),
                            _SocialButton(
                              label: l10n.continueWithApple,
                              icon: Icons.apple,
                              dark: true,
                              onPressed: () =>
                                  _handleSocialLogin(_authService.signInWithApple),
                            ),
                          ],
                          const SizedBox(height: 24.0),
                          Row(
                            children: [
                              const Expanded(child: Divider()),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                child: Text(
                                  l10n.orWithEmail,
                                  style: TextStyle(color: Colors.grey.shade500),
                                ),
                              ),
                              const Expanded(child: Divider()),
                            ],
                          ),
                          const SizedBox(height: 24.0),
                          CustomInputField(
                            controller: _emailController,
                            labelText: l10n.emailLabel,
                            icon: Icons.email_outlined,
                          ),
                          const SizedBox(height: 16.0),
                          CustomPasswordField(
                            controller: _passwordController,
                          ),
                          const SizedBox(height: 24.0),
                          SecondaryButton(
                            text: l10n.loginButton,
                            onPressed: _performLogin,
                          ),
                          const SizedBox(height: 16.0),
                          PrimaryButton(
                            text: l10n.createAccountButton,
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const RegisterScreen(),
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const ForgotPasswordScreen(),
                                ),
                              );
                            },
                            child: Text(l10n.forgotPasswordLink),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
          _SpcFooter(),
        ],
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color? iconColor;
  final bool dark;
  final VoidCallback onPressed;

  const _SocialButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.iconColor,
    this.dark = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = dark ? Colors.black : Colors.white;
    final fg = dark ? Colors.white : Colors.black87;
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        icon: Icon(icon, color: iconColor ?? fg, size: 26),
        label: Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: fg,
          ),
        ),
        style: OutlinedButton.styleFrom(
          backgroundColor: bg,
          padding: const EdgeInsets.symmetric(vertical: 14),
          side: BorderSide(color: Colors.grey.shade300),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: onPressed,
      ),
    );
  }
}

class _SpcFooter extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20, top: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Developed by ',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
          ),
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 4,
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.asset(
              'assets/logo/spc_logo_compressed.jpg',
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }
}
