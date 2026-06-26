import 'package:flutter/material.dart';
import 'package:warrior_path/screens/WelcomeScreen.dart';
import 'package:warrior_path/services/auth_service.dart';

/// Flujo de eliminación de cuenta reutilizable (App Store Guideline 5.1.1(v)).
/// Pide confirmación, muestra un loader mientras la Cloud Function borra los
/// datos y la cuenta de Auth, y al terminar lleva al usuario a la pantalla de
/// bienvenida. Se usa tanto en el perfil del maestro como en el del alumno.
Future<void> deleteAccountFlow(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Eliminar cuenta'),
      content: const Text(
        'Se eliminarán de forma permanente tu cuenta y tus datos personales '
        '(perfil, membresías y perfiles de hijos a tu cargo).\n\n'
        'Esta acción no se puede deshacer.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: const Text(
            'Eliminar mi cuenta',
            style: TextStyle(color: Colors.red),
          ),
        ),
      ],
    ),
  );

  if (confirmed != true || !context.mounted) return;

  // Loader bloqueante mientras se procesa el borrado.
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const PopScope(
      canPop: false,
      child: Center(child: CircularProgressIndicator()),
    ),
  );

  try {
    await AuthService().deleteAccount();
    if (!context.mounted) return;
    // Cierra el loader y limpia toda la pila de navegación.
    Navigator.of(context, rootNavigator: true).pop();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      (route) => false,
    );
  } catch (e) {
    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pop(); // cierra el loader
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('No se pudo eliminar la cuenta. Intentá de nuevo. ($e)'),
      ),
    );
  }
}
