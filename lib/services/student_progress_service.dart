import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Escrituras sobre el progreso de un alumno, compartidas entre la vista del
/// alumno y la del maestro.
///
/// Existe para que las dos partes usen exactamente las mismas rutas y el mismo
/// criterio de merge. El punto delicado es que ahora hay **dos** listas de
/// técnicas conviviendo en el mismo documento:
///
///  - `assignedTechniqueIds`      → las que puso el maestro (valen para logros)
///  - `selfReportedTechniqueIds`  → las que declaró el alumno (a confirmar)
///
/// Todas las escrituras usan `arrayUnion`/`arrayRemove` en vez de reescribir el
/// array completo: si dos personas editan a la vez (típico: el maestro tiene la
/// pantalla abierta mientras el alumno marca algo), reescribir pisaría lo del
/// otro sin aviso.
class StudentProgressService {
  StudentProgressService._();

  /// Tipos de entrada en `members/{uid}/progressionHistory`.
  static const String historyPromotion = 'level_promotion';
  static const String historySelfDeclared = 'level_self_declared';
  static const String historyRoleChange = 'role_change';

  static DocumentReference<Map<String, dynamic>> _memberRef(
    String schoolId,
    String studentId,
  ) =>
      FirebaseFirestore.instance
          .collection('schools')
          .doc(schoolId)
          .collection('members')
          .doc(studentId);

  // ── Técnicas ──────────────────────────────────────────────────────────────

  /// El alumno marca (o desmarca) una técnica que dice saber.
  ///
  /// Nunca toca `assignedTechniqueIds`: lo que confirmó el maestro no se puede
  /// pisar desde el lado del alumno.
  static Future<void> setSelfReportedTechnique({
    required String schoolId,
    required String studentId,
    required String disciplineId,
    required String techniqueId,
    required bool reported,
  }) {
    final field = 'progress.$disciplineId.selfReportedTechniqueIds';
    return _memberRef(schoolId, studentId).update({
      field: reported
          ? FieldValue.arrayUnion([techniqueId])
          : FieldValue.arrayRemove([techniqueId]),
    });
  }

  /// El maestro confirma una técnica que había declarado el alumno: pasa de la
  /// lista de declaradas a la de asignadas, en una sola operación.
  static Future<void> confirmSelfReportedTechnique({
    required String schoolId,
    required String studentId,
    required String disciplineId,
    required String techniqueId,
  }) {
    return _memberRef(schoolId, studentId).update({
      'progress.$disciplineId.assignedTechniqueIds':
          FieldValue.arrayUnion([techniqueId]),
      'progress.$disciplineId.selfReportedTechniqueIds':
          FieldValue.arrayRemove([techniqueId]),
    });
  }

  /// Quita una técnica, sin importar de qué lista venga. Se sacan de las dos
  /// para que no reaparezca por el otro lado.
  static Future<void> removeTechnique({
    required String schoolId,
    required String studentId,
    required String disciplineId,
    required String techniqueId,
  }) {
    return _memberRef(schoolId, studentId).update({
      'progress.$disciplineId.assignedTechniqueIds':
          FieldValue.arrayRemove([techniqueId]),
      'progress.$disciplineId.selfReportedTechniqueIds':
          FieldValue.arrayRemove([techniqueId]),
    });
  }

  /// El maestro asigna varias técnicas de una (desde la pantalla de asignación).
  ///
  /// [added] y [removed] se calculan contra lo que había al abrir la pantalla,
  /// para no reescribir el array entero y así no borrar lo que el alumno haya
  /// declarado mientras tanto.
  static Future<void> applyTeacherAssignments({
    required String schoolId,
    required String studentId,
    required String disciplineId,
    required Set<String> added,
    required Set<String> removed,
  }) {
    if (added.isEmpty && removed.isEmpty) return Future.value();

    final update = <String, dynamic>{};
    if (added.isNotEmpty) {
      update['progress.$disciplineId.assignedTechniqueIds'] =
          FieldValue.arrayUnion(added.toList());
      // Si el maestro asigna algo que el alumno ya había declarado, deja de
      // estar "pendiente de confirmar".
      update['progress.$disciplineId.selfReportedTechniqueIds'] =
          FieldValue.arrayRemove(added.toList());
    }
    if (removed.isNotEmpty) {
      // Se hace en dos pasos porque Firestore no admite dos operaciones de
      // array sobre el mismo campo en la misma escritura.
      return _memberRef(schoolId, studentId).update(update).then((_) =>
          _memberRef(schoolId, studentId).update({
            'progress.$disciplineId.assignedTechniqueIds':
                FieldValue.arrayRemove(removed.toList()),
          }));
    }
    return _memberRef(schoolId, studentId).update(update);
  }

  // ── Nivel ─────────────────────────────────────────────────────────────────

  /// El alumno declara el cinturón que ya tenía.
  ///
  /// Se aplica directo (decisión del usuario) pero queda registrado en el
  /// historial como auto-declarado, con su propio uid en `promotedBy`, para que
  /// el maestro pueda distinguirlo de una promoción que dio él.
  static Future<void> selfDeclareLevel({
    required String schoolId,
    required String studentId,
    required String disciplineId,
    required String disciplineName,
    required String? previousLevelId,
    required String newLevelId,
  }) async {
    final firestore = FirebaseFirestore.instance;
    final memberRef = _memberRef(schoolId, studentId);
    final batch = firestore.batch();

    batch.update(memberRef, {
      'progress.$disciplineId.currentLevelId': newLevelId,
    });

    batch.set(memberRef.collection('progressionHistory').doc(), {
      'date': Timestamp.now(),
      'previousLevelId': previousLevelId,
      'newLevelId': newLevelId,
      'disciplineId': disciplineId,
      'disciplineName': disciplineName,
      'type': historySelfDeclared,
      'notes': '',
      'promotedBy': FirebaseAuth.instance.currentUser?.uid,
    });

    await batch.commit();
  }

  // ── Lectura ───────────────────────────────────────────────────────────────

  /// Técnicas declaradas por el alumno y todavía sin confirmar.
  static List<String> selfReportedIds(
    Map<String, dynamic>? progress,
    String disciplineId,
  ) {
    final d = progress?[disciplineId] as Map<String, dynamic>?;
    return List<String>.from(d?['selfReportedTechniqueIds'] ?? const []);
  }

  /// Técnicas confirmadas por el maestro. Son las únicas que cuentan para los
  /// logros: si contaran las declaradas, cualquiera se marca todo y los
  /// desbloquea sin entrenar.
  static List<String> assignedIds(
    Map<String, dynamic>? progress,
    String disciplineId,
  ) {
    final d = progress?[disciplineId] as Map<String, dynamic>?;
    return List<String>.from(d?['assignedTechniqueIds'] ?? const []);
  }
}
