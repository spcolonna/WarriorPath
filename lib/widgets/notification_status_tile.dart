import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/notification_service.dart';

/// Muestra si este dispositivo va a recibir notificaciones, y permite
/// reintentar el registro.
///
/// Existe porque el registro puede fallar en silencio (permiso denegado, o el
/// token de APNS que no llegó a tiempo al arrancar). Sin esto, un maestro puede
/// pasar semanas sin enterarse de que no le llegan las solicitudes de ingreso,
/// creyendo que simplemente nadie se postula.
class NotificationStatusTile extends StatefulWidget {
  const NotificationStatusTile({super.key});

  @override
  State<NotificationStatusTile> createState() => _NotificationStatusTileState();
}

class _NotificationStatusTileState extends State<NotificationStatusTile> {
  NotificationDiagnostics? _status;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final status = await NotificationService().diagnose();
    if (mounted) setState(() => _status = status);
  }

  Future<void> _retry() async {
    setState(() => _busy = true);
    await NotificationService().ensureTokenRegistered();
    await _check();
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final status = _status;

    // Mientras se averigua, no se muestra nada: evita el parpadeo de un
    // cartel de error que después resulta que estaba todo bien.
    if (status == null) return const SizedBox.shrink();

    if (status.isWorking) {
      return ListTile(
        leading: const Icon(Icons.notifications_active, color: Colors.green),
        title: Text(l10n.notificationsActive),
        subtitle: Text(l10n.notificationsActiveSubtitle),
      );
    }

    // Sin permiso hay que ir a los ajustes del sistema; reintentar no sirve.
    final needsSystemSettings = !status.permissionGranted;

    return Card(
      color: Colors.orange.withValues(alpha: 0.08),
      child: ListTile(
        leading: const Icon(Icons.notifications_off, color: Colors.orange),
        title: Text(l10n.notificationsOff),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(needsSystemSettings
                ? l10n.notificationsOffPermission
                : l10n.notificationsOffDevice),
            // El detalle técnico es lo que permite distinguir un problema de
            // configuración de APNs de uno del dispositivo.
            if (status.errorDetail != null) ...[
              const SizedBox(height: 4),
              Text(
                status.errorDetail!,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
        isThreeLine: status.errorDetail != null,
        trailing: needsSystemSettings
            ? null
            : _busy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : TextButton(
                    onPressed: _retry,
                    child: Text(l10n.retry),
                  ),
      ),
    );
  }
}
