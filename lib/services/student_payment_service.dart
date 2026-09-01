import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Estados de un documento de `payments`.
///
/// Los pagos viejos no tienen el campo: se leen con [statusOf], que los trata
/// como confirmados. Así no hace falta migrar nada.
class PaymentStatus {
  PaymentStatus._();

  /// Cargado por el maestro, o declarado por el alumno y ya confirmado.
  /// Es el único estado que cuenta para los ingresos de la escuela.
  static const String confirmed = 'confirmed';

  /// Declarado por el alumno, esperando que el maestro lo valide.
  static const String pendingConfirmation = 'pending_confirmation';
}

/// Métodos de pago que puede declarar el alumno.
class PaymentMethod {
  PaymentMethod._();

  static const String cash = 'efectivo';
  static const String transfer = 'transferencia';
  static const String other = 'otro';

  static const List<String> all = [cash, transfer, other];
}

/// Alta y confirmación de pagos.
///
/// La regla que ordena todo: **sólo los pagos `confirmed` cuentan como plata
/// cobrada**. Un pago declarado por el alumno existe y se ve, pero no suma a
/// los ingresos hasta que el maestro lo confirma.
class StudentPaymentService {
  StudentPaymentService._();

  static DocumentReference<Map<String, dynamic>> _memberRef(
    String schoolId,
    String studentId,
  ) =>
      FirebaseFirestore.instance
          .collection('schools')
          .doc(schoolId)
          .collection('members')
          .doc(studentId);

  static CollectionReference<Map<String, dynamic>> _payments(
    String schoolId,
    String studentId,
  ) =>
      _memberRef(schoolId, studentId).collection('payments');

  /// Estado de un pago, tolerando los documentos viejos que no tienen el campo.
  static String statusOf(Map<String, dynamic>? data) =>
      data?['status'] as String? ?? PaymentStatus.confirmed;

  static bool isConfirmed(Map<String, dynamic>? data) =>
      statusOf(data) == PaymentStatus.confirmed;

  /// El alumno declara un pago que ya hizo. Queda pendiente de confirmación.
  static Future<void> declare({
    required String schoolId,
    required String studentId,
    required String studentName,
    required String concept,
    required double amount,
    required String currency,
    required DateTime paymentDate,
    String? paymentPlanId,
    String? paymentMethod,
  }) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return _payments(schoolId, studentId).add({
      'paymentDate': Timestamp.fromDate(paymentDate),
      'concept': concept,
      'amount': amount,
      'currency': currency,
      'paymentPlanId': paymentPlanId,
      'paymentMethod': paymentMethod,
      'studentId': studentId,
      'studentName': studentName,
      'schoolId': schoolId,
      'status': PaymentStatus.pendingConfirmation,
      'declaredBy': uid,
      'recordedBy': uid,
      'createdOn': FieldValue.serverTimestamp(),
    });
  }

  /// El maestro confirma un pago declarado por el alumno.
  ///
  /// Además cierra el recordatorio del período correspondiente, que hasta ahora
  /// se creaba y quedaba `pending` para siempre: el alumno pagaba y le seguía
  /// figurando la cuota vencida.
  static Future<void> confirm({
    required String schoolId,
    required String studentId,
    required String paymentId,
    required DateTime paymentDate,
  }) async {
    await _payments(schoolId, studentId).doc(paymentId).update({
      'status': PaymentStatus.confirmed,
      'confirmedBy': FirebaseAuth.instance.currentUser?.uid,
      'confirmedAt': FieldValue.serverTimestamp(),
    });

    await _closeReminderForPeriod(
      schoolId: schoolId,
      studentId: studentId,
      date: paymentDate,
    );
  }

  /// El maestro corrige lo que declaró el alumno y lo confirma en un solo paso.
  ///
  /// Es el caso real: el alumno puso 1500 pero entregó 1200. Se guarda el monto
  /// original en `declaredAmount` para que quede rastro de la diferencia y no
  /// parezca que el alumno declaró lo que finalmente se registró.
  static Future<void> correctAndConfirm({
    required String schoolId,
    required String studentId,
    required String paymentId,
    required String concept,
    required double amount,
    required DateTime paymentDate,
    required double declaredAmount,
    String? paymentPlanId,
  }) async {
    await _payments(schoolId, studentId).doc(paymentId).update({
      'concept': concept,
      'amount': amount,
      'paymentDate': Timestamp.fromDate(paymentDate),
      'paymentPlanId': paymentPlanId,
      'status': PaymentStatus.confirmed,
      'confirmedBy': FirebaseAuth.instance.currentUser?.uid,
      'confirmedAt': FieldValue.serverTimestamp(),
      // Sólo se deja rastro si efectivamente hubo corrección.
      if (declaredAmount != amount) 'declaredAmount': declaredAmount,
    });

    await _closeReminderForPeriod(
      schoolId: schoolId,
      studentId: studentId,
      date: paymentDate,
    );
  }

  /// El maestro rechaza un pago declarado: se borra.
  static Future<void> reject({
    required String schoolId,
    required String studentId,
    required String paymentId,
  }) {
    return _payments(schoolId, studentId).doc(paymentId).delete();
  }

  /// Marca como pagado el recordatorio del mes del pago, si existe y sigue
  /// pendiente. El `periodKey` tiene formato `YYYY-MM`, igual que lo genera
  /// `generateMonthlyPaymentReminders` en las Cloud Functions.
  static Future<void> _closeReminderForPeriod({
    required String schoolId,
    required String studentId,
    required DateTime date,
  }) async {
    final periodKey =
        '${date.year}-${date.month.toString().padLeft(2, '0')}';

    final snap = await _memberRef(schoolId, studentId)
        .collection('paymentReminders')
        .where('periodKey', isEqualTo: periodKey)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();

    if (snap.docs.isEmpty) return;

    await snap.docs.first.reference.update({
      'status': 'paid',
      'paidAt': FieldValue.serverTimestamp(),
    });
  }

  /// Todos los pagos por confirmar de la escuela, sin importar de qué alumno.
  ///
  /// Alimenta el contador y el filtro del maestro, para que no dependa de haber
  /// visto la notificación. Necesita el índice compuesto de `payments`
  /// (`schoolId` + `status`) declarado en `firestore.indexes.json`.
  static Stream<QuerySnapshot<Map<String, dynamic>>> pendingInSchool(
    String schoolId,
  ) {
    return FirebaseFirestore.instance
        .collectionGroup('payments')
        .where('schoolId', isEqualTo: schoolId)
        .where('status', isEqualTo: PaymentStatus.pendingConfirmation)
        .snapshots();
  }

  /// Pagos declarados y todavía sin confirmar de un alumno.
  static Stream<QuerySnapshot<Map<String, dynamic>>> pendingOf({
    required String schoolId,
    required String studentId,
  }) {
    return _payments(schoolId, studentId)
        .where('status', isEqualTo: PaymentStatus.pendingConfirmation)
        .snapshots();
  }
}
