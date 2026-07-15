import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/session_provider.dart';
import 'post_auth_navigator.dart';

/// Lógica para abandonar el wizard de creación de escuela descartando todo.
class SchoolSetupService {
  SchoolSetupService._();

  /// Muestra confirmación y, si acepta, descarta la escuela a medio crear
  /// (borrado recursivo + limpieza del user doc vía callable) y rutea al
  /// usuario a un estado usable (elegir rol, u otra escuela si tenía).
  ///
  /// [schoolId] puede ser null si todavía no se creó la escuela (paso inicial
  /// del wizard): en ese caso sólo se resetea el `wizardStep`.
  static Future<void> exitAndDiscard(
    BuildContext context, {
    String? schoolId,
  }) async {
    final l10n = AppLocalizations.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.exitAndDiscardConfirmTitle),
        content: Text(l10n.exitAndDiscardConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              l10n.exitAndDiscard,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    // Loader modal mientras corre la callable (borrado recursivo).
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await FirebaseFunctions.instance
          .httpsCallable('abandonSchoolSetup')
          .call({'schoolId': schoolId});

      // La sesión pudo haber quedado apuntando a la escuela descartada.
      if (context.mounted) {
        Provider.of<SessionProvider>(context, listen: false).clearSession();
      }

      final user = FirebaseAuth.instance.currentUser;
      if (!context.mounted) return;
      Navigator.of(context).pop(); // cerrar loader

      // Re-rutear leyendo el user doc ya actualizado (wizardStep nuevo).
      if (user != null && context.mounted) {
        await navigateAfterAuth(context, user);
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop(); // cerrar loader
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.genericErrorContent(e.toString()))),
        );
      }
    }
  }
}
