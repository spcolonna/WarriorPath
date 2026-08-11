import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:warrior_path/services/student_payment_service.dart';

import '../../../l10n/app_localizations.dart';
import '../declare_payment_dialog.dart';

class PaymentsTabScreen extends StatelessWidget {
  final String schoolId;
  final String memberId;

  const PaymentsTabScreen({
    super.key,
    required this.schoolId,
    required this.memberId,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(title: Text(l10n.myPayments)),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add_card),
        label: Text(l10n.declarePayment),
        onPressed: () async {
          final name = (await FirebaseFirestore.instance
                      .collection('schools')
                      .doc(schoolId)
                      .collection('members')
                      .doc(memberId)
                      .get())
                  .data()?['displayName'] as String? ??
              '';
          if (!context.mounted) return;
          await showDialog(
            context: context,
            builder: (_) => DeclarePaymentDialog(
              schoolId: schoolId,
              studentId: memberId,
              studentName: name,
            ),
          );
        },
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _DueStatusSection(schoolId: schoolId, memberId: memberId),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              child: Text(
                l10n.paymentHistory,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          _PaymentHistoryList(schoolId: schoolId, memberId: memberId),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}

// ── Estado de pago (hero) ──────────────────────────────────────────────────────

class _PlanInfo {
  final String title;
  final double amount;
  final String currency;
  final DateTime nextDue;

  const _PlanInfo({
    required this.title,
    required this.amount,
    required this.currency,
    required this.nextDue,
  });
}

class _DueStatusSection extends StatelessWidget {
  final String schoolId;
  final String memberId;

  const _DueStatusSection({required this.schoolId, required this.memberId});

  Future<_PlanInfo?> _loadPlanInfo() async {
    final firestore = FirebaseFirestore.instance;
    final memberDoc = await firestore
        .collection('schools')
        .doc(schoolId)
        .collection('members')
        .doc(memberId)
        .get();
    final planId = memberDoc.data()?['assignedPaymentPlanId'] as String?;
    if (planId == null) return null;

    final results = await Future.wait([
      firestore
          .collection('schools')
          .doc(schoolId)
          .collection('paymentPlans')
          .doc(planId)
          .get(),
      firestore.collection('schools').doc(schoolId).get(),
    ]);
    final planDoc = results[0];
    if (!planDoc.exists) return null;
    final planData = planDoc.data() as Map<String, dynamic>;
    final schoolDoc = results[1];
    final financials =
        schoolDoc.data()?['financials'] as Map<String, dynamic>? ?? {};
    // Misma regla que usa el maestro en Gestionar Finanzas: si el día de
    // vencimiento de este mes ya pasó, el próximo vencimiento es el mes que viene.
    final dueDay = (financials['paymentDueDay'] as int?) ?? 5;
    final now = DateTime.now();
    final thisMonthDue = DateTime(now.year, now.month, dueDay);
    final nextDue = thisMonthDue.isBefore(now)
        ? DateTime(now.year, now.month + 1, dueDay)
        : thisMonthDue;

    return _PlanInfo(
      title: planData['title'] as String? ?? '',
      amount: (planData['amount'] as num?)?.toDouble() ?? 0.0,
      currency: planData['currency'] as String? ?? 'UYU',
      nextDue: nextDue,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('schools')
            .doc(schoolId)
            .collection('members')
            .doc(memberId)
            .collection('paymentReminders')
            .where('status', isEqualTo: 'pending')
            .limit(1)
            .snapshots(),
        builder: (context, reminderSnap) {
          if (reminderSnap.connectionState == ConnectionState.waiting) {
            return const _DueStatusSkeleton();
          }
          final pendingDocs = reminderSnap.data?.docs ?? [];
          if (pendingDocs.isNotEmpty) {
            final reminder = pendingDocs.first.data() as Map<String, dynamic>;
            return _PendingPaymentCard(reminder: reminder);
          }

          return FutureBuilder<_PlanInfo?>(
            future: _loadPlanInfo(),
            builder: (context, planSnap) {
              if (planSnap.connectionState == ConnectionState.waiting) {
                return const _DueStatusSkeleton();
              }
              final info = planSnap.data;
              if (info == null) return const _NoPlanCard();
              return _UpToDateCard(info: info);
            },
          );
        },
      ),
    );
  }
}

String _formatAmount(num amount) =>
    amount % 1 == 0 ? amount.toInt().toString() : amount.toStringAsFixed(2);

class _DueStatusSkeleton extends StatelessWidget {
  const _DueStatusSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 92,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(18),
      ),
      alignment: Alignment.center,
      child: const SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }
}

class _NoPlanCard extends StatelessWidget {
  const _NoPlanCard();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.grey.shade500, size: 26),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              l10n.noPaymentPlanAssigned,
              style: TextStyle(color: Colors.grey.shade700, fontSize: 13.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingPaymentCard extends StatelessWidget {
  final Map<String, dynamic> reminder;
  const _PendingPaymentCard({required this.reminder});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    const color = Color(0xFFE0682B);
    final concept = reminder['concept'] as String? ?? '';
    final amount = (reminder['amount'] as num?) ?? 0;
    final currency = reminder['currency'] as String? ?? 'UYU';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, Color(0xFFB94A1B)],
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: Colors.white, size: 30),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.paymentStatusPending,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$concept · ${_formatAmount(amount)} $currency',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.92),
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.pendingPaymentContactTeacher,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UpToDateCard extends StatelessWidget {
  final _PlanInfo info;
  const _UpToDateCard({required this.info});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final primary = Theme.of(context).primaryColor;
    const green = Color(0xFF2E9E5B);
    final nextDueLabel =
        DateFormat("d 'de' MMMM", l10n.localeName).format(info.nextDue);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: green.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle, color: green, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.paymentStatusUpToDate,
                  style: const TextStyle(
                    color: green,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${info.title} · ${_formatAmount(info.amount)} ${info.currency}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.event_outlined, size: 15, color: primary),
                    const SizedBox(width: 6),
                    Text(
                      l10n.nextPaymentDue(nextDueLabel),
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Historial ───────────────────────────────────────────────────────────────

class _PaymentHistoryList extends StatelessWidget {
  final String schoolId;
  final String memberId;

  const _PaymentHistoryList({required this.schoolId, required this.memberId});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('schools')
          .doc(schoolId)
          .collection('members')
          .doc(memberId)
          .collection('payments')
          .orderBy('paymentDate', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }
        if (snapshot.hasError) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(l10n.errorLoadingPaymentHistory),
            ),
          );
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.receipt_long_outlined,
                        size: 44, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    Text(
                      l10n.noPaymentsRegisteredYet,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final payment = docs[index].data() as Map<String, dynamic>;
                return _PaymentHistoryTile(payment: payment, l10n: l10n);
              },
              childCount: docs.length,
            ),
          ),
        );
      },
    );
  }
}

class _PaymentHistoryTile extends StatelessWidget {
  final Map<String, dynamic> payment;
  final AppLocalizations l10n;

  const _PaymentHistoryTile({required this.payment, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final date = (payment['paymentDate'] as Timestamp).toDate();
    final formattedDate = DateFormat.yMMMMd(l10n.localeName).format(date);
    final amount = (payment['amount'] as num?) ?? 0;
    final currency = payment['currency'] as String? ?? 'UYU';

    // Un pago declarado por el alumno todavía no es un pago cobrado: se
    // distingue para que no crea que ya está resuelto.
    final confirmed = StudentPaymentService.isConfirmed(payment);
    final accent = confirmed ? const Color(0xFF2E9E5B) : Colors.orange.shade700;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: confirmed ? Colors.grey.shade200 : Colors.orange.shade200,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              confirmed ? Icons.check : Icons.hourglass_empty,
              color: accent,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  payment['concept'] as String? ?? '',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  confirmed
                      ? l10n.paidOn(formattedDate)
                      : '${l10n.paidOn(formattedDate)} · ${l10n.pendingConfirmation}',
                  style: TextStyle(
                    fontSize: 12,
                    color: confirmed ? Colors.grey.shade500 : accent,
                    fontWeight:
                        confirmed ? FontWeight.normal : FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${_formatAmount(amount)} $currency',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
