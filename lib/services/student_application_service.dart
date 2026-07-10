import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

/// Lógica compartida para aceptar/rechazar solicitudes de ingreso de alumnos.
///
/// Extraída de [students_tab_screen.dart] para poder usarla también desde la
/// home del maestro. Aceptar pide elegir disciplina (diálogo), inscribe al
/// alumno en el primer nivel de esa disciplina y activa la membresía.
class StudentApplicationService {
  StudentApplicationService._();

  /// Flujo completo de aceptación: diálogo de disciplina + inscripción.
  /// Devuelve true si el alumno quedó aceptado.
  static Future<bool> accept(
    BuildContext context, {
    required String schoolId,
    required String userId,
  }) async {
    final l10n = AppLocalizations.of(context);
    final disciplines = await FirebaseFirestore.instance
        .collection('schools')
        .doc(schoolId)
        .collection('disciplines')
        .get();

    if (!context.mounted) return false;

    if (disciplines.docs.isEmpty) {
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.errorTitle),
          content: Text(l10n.noDisciplinesAvailable),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(l10n.ok)),
          ],
        ),
      );
      return false;
    }

    final selectedDisciplineId = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.enrollInDiscipline),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.selectDisciplineForStudent),
              const SizedBox(height: 16),
              ...disciplines.docs.map((doc) => ListTile(
                    title: Text(doc['name']),
                    onTap: () => Navigator.of(ctx).pop(doc.id),
                  )),
            ],
          ),
        ),
      ),
    );

    if (selectedDisciplineId == null || !context.mounted) return false;
    return _confirmAcceptance(context,
        schoolId: schoolId,
        userId: userId,
        disciplineId: selectedDisciplineId);
  }

  /// Rechaza (borra) una solicitud pendiente.
  static Future<void> reject(
    BuildContext context, {
    required String schoolId,
    required String userId,
  }) async {
    final l10n = AppLocalizations.of(context);
    final firestore = FirebaseFirestore.instance;
    final batch = firestore.batch();
    batch.delete(firestore
        .collection('schools')
        .doc(schoolId)
        .collection('members')
        .doc(userId));
    // Sólo la entrada de ESTA escuela: si el alumno tiene otra postulación
    // pendiente en paralelo, no se debe perder (bug anterior borraba el mapa entero).
    batch.update(firestore.collection('users').doc(userId),
        {'pendingApplications.$schoolId': FieldValue.delete()});
    await batch.commit();
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.applicationRejected)));
    }
  }

  static Future<bool> _confirmAcceptance(
    BuildContext context, {
    required String schoolId,
    required String userId,
    required String disciplineId,
  }) async {
    final l10n = AppLocalizations.of(context);
    final firestore = FirebaseFirestore.instance;

    try {
      final disciplineRef = firestore
          .collection('schools')
          .doc(schoolId)
          .collection('disciplines')
          .doc(disciplineId);
      final levelsQuery =
          await disciplineRef.collection('levels').orderBy('order').limit(1).get();

      if (levelsQuery.docs.isEmpty) {
        throw Exception('La disciplina seleccionada no tiene niveles configurados.');
      }
      final initialLevelId = levelsQuery.docs.first.id;

      final batch = firestore.batch();
      final memberRef = firestore
          .collection('schools')
          .doc(schoolId)
          .collection('members')
          .doc(userId);
      final userRef = firestore.collection('users').doc(userId);

      batch.update(memberRef, {
        'status': 'active',
        'powerLevel': FieldValue.increment(0), // materializa el campo p/ranking
        'progress.$disciplineId': {
          'currentLevelId': initialLevelId,
          'enrollmentDate': FieldValue.serverTimestamp(),
          'assignedTechniqueIds': [],
          'role': 'alumno'
        },
        'joinDate': FieldValue.serverTimestamp(),
        'role': FieldValue.delete(), // Eliminamos el campo de rol antiguo
      });

      batch.set(userRef, {
        'activeMemberships': {schoolId: 'alumno'},
        'pendingApplications': FieldValue.delete(),
      }, SetOptions(merge: true));

      await batch.commit();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(l10n.studentAcceptedSuccess),
            backgroundColor: Colors.green));
      }
      return true;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
      return false;
    }
  }
}
