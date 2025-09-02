import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PaymentsTabScreen extends StatelessWidget {
  final String schoolId;
  final String memberId;

  const PaymentsTabScreen({
    Key? key,
    required this.schoolId,
    required this.memberId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Pagos'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Leemos la misma sub-colección que el maestro escribe
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
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Error al cargar tu historial de pagos.'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Aún no tienes pagos registrados.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ),
            );
          }

          final paymentDocs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: paymentDocs.length,
            itemBuilder: (context, index) {
              final payment = paymentDocs[index].data() as Map<String, dynamic>;
              final date = (payment['paymentDate'] as Timestamp).toDate();
              final formattedDate = DateFormat('dd de MMMM de yyyy', 'es_ES').format(date);

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 40,
                  ),
                  title: Text(
                    '${payment['amount']} ${payment['currency']}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  subtitle: Text('${payment['concept']}\nPagado el $formattedDate'),
                  isThreeLine: true,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
