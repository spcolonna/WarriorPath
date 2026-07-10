import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:warrior_path/screens/WelcomeScreen.dart';
import 'package:warrior_path/services/post_auth_navigator.dart';
import 'package:warrior_path/theme/AppColors.dart';
import '../l10n/app_localizations.dart';

/// Pantalla que se muestra tras registrarse (o al intentar entrar con un mail
/// sin confirmar). Bloquea el avance hasta que el usuario verifica su correo.
/// Recién ahí se crea su documento en Firestore (ver [navigateAfterAuth]).
class VerifyEmailScreen extends StatefulWidget {
  final String email;
  const VerifyEmailScreen({super.key, required this.email});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  bool _isChecking = false;
  int _resendCooldown = 0;
  Timer? _cooldownTimer;

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    setState(() => _resendCooldown = 30);
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_resendCooldown <= 1) {
        t.cancel();
        if (mounted) setState(() => _resendCooldown = 0);
      } else {
        if (mounted) setState(() => _resendCooldown--);
      }
    });
  }

  Future<void> _resendEmail() async {
    final l10n = AppLocalizations.of(context);
    if (_resendCooldown > 0) return;
    try {
      await FirebaseAuth.instance.currentUser?.sendEmailVerification();
      _startCooldown();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.verifyEmailResent)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.genericErrorContent(e.toString()))),
        );
      }
    }
  }

  Future<void> _checkVerified() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _isChecking = true);
    try {
      await FirebaseAuth.instance.currentUser?.reload();
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && user.emailVerified) {
        // Forzamos el refresco del ID token para que incluya
        // email_verified=true; si no, las reglas de Firestore lo verían en
        // false (el token queda cacheado hasta 1h) y negarían crear el doc.
        await user.getIdToken(true);
        if (!mounted) return;
        await navigateAfterAuth(context, user);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.verifyEmailNotYet)),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                Icons.mark_email_unread_outlined,
                size: 80,
                color: AppColors.primaryColor,
              ),
              const SizedBox(height: 24),
              Text(
                l10n.verifyEmailTitle,
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.verifyEmailMessage(widget.email),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15, height: 1.5),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _isChecking ? null : _checkVerified,
                child: _isChecking
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(l10n.verifyEmailConfirmedButton),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _resendCooldown > 0 ? null : _resendEmail,
                child: Text(
                  _resendCooldown > 0
                      ? l10n.verifyEmailResendIn(_resendCooldown)
                      : l10n.verifyEmailResendButton,
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _logout,
                style: TextButton.styleFrom(foregroundColor: AppColors.textLight),
                child: Text(l10n.verifyEmailBackToLogin),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
