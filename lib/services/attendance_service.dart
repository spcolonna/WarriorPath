import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Escrituras sobre `schools/{id}/attendanceRecords`.
///
/// Existe para unificar las tres formas en que hoy se registra asistencia (el
/// maestro cargando una clase pasada, el auto check-in del alumno, y la carga
/// pasada del propio alumno), que hasta ahora estaban duplicadas y **no
/// coincidían entre sí**.
///
/// La diferencia importante era la fecha: el maestro la normalizaba a
/// medianoche y el check-in del alumno guardaba `Timestamp.now()`. Como la
/// deduplicación es por (fecha, scheduleTitle), un mismo día podía terminar con
/// dos documentos para la misma clase y el alumno aparecía dos veces.
class AttendanceService {
  AttendanceService._();

  /// Cuántos días hacia atrás puede cargar el alumno. El maestro no tiene tope.
  static const int studentBackfillDays = 30;

  static CollectionReference<Map<String, dynamic>> _records(String schoolId) =>
      FirebaseFirestore.instance
          .collection('schools')
          .doc(schoolId)
          .collection('attendanceRecords');

  /// Toda fecha se guarda a medianoche: es la clave de deduplicación junto con
  /// el título de la clase.
  static DateTime normalize(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Marca presente a [studentId] en una clase.
  ///
  /// Si ya existe el registro de esa fecha y clase, lo agrega con `arrayUnion`;
  /// si no, lo crea. Es idempotente: marcar dos veces no duplica nada, y el
  /// premio de poder lo controla la Cloud Function con `awardedPowerStudentIds`.
  static Future<void> markPresent({
    required String schoolId,
    required String studentId,
    required String scheduleTitle,
    required DateTime date,
    String? scheduleId,
  }) async {
    final day = normalize(date);
    final next = day.add(const Duration(days: 1));

    final snap = await _records(schoolId)
        .where('scheduleTitle', isEqualTo: scheduleTitle)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(day))
        .where('date', isLessThan: Timestamp.fromDate(next))
        .limit(1)
        .get();

    if (snap.docs.isNotEmpty) {
      await snap.docs.first.reference.update({
        'presentStudentIds': FieldValue.arrayUnion([studentId]),
      });
      return;
    }

    await _records(schoolId).add({
      'date': Timestamp.fromDate(day),
      'scheduleTitle': scheduleTitle,
      if (scheduleId != null) 'scheduleId': scheduleId,
      'schoolId': schoolId,
      'presentStudentIds': [studentId],
      'recordedBy': FirebaseAuth.instance.currentUser?.uid,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Quita a un alumno de un registro (lo usa el maestro al corregir).
  static Future<void> removePresent({
    required String schoolId,
    required String recordId,
    required String studentId,
  }) {
    return _records(schoolId).doc(recordId).update({
      'presentStudentIds': FieldValue.arrayRemove([studentId]),
    });
  }

  /// Clases dictadas un día concreto, según el día de la semana del horario.
  static Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
      schedulesForDate({
    required String schoolId,
    required DateTime date,
  }) async {
    final snap = await FirebaseFirestore.instance
        .collection('schools')
        .doc(schoolId)
        .collection('classSchedules')
        .where('dayOfWeek', isEqualTo: date.weekday)
        .get();

    final docs = snap.docs.toList()
      ..sort((a, b) => (a.data()['startTime'] as String? ?? '')
          .compareTo(b.data()['startTime'] as String? ?? ''));
    return docs;
  }

  /// Fecha mínima que el alumno puede cargar hacia atrás.
  static DateTime studentEarliestDate() =>
      normalize(DateTime.now().subtract(const Duration(days: studentBackfillDays)));
}
