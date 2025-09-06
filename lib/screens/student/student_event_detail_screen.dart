import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:warrior_path/models/event_model.dart';

class StudentEventDetailScreen extends StatefulWidget {
  final String schoolId;
  final String eventId;

  const StudentEventDetailScreen({
    Key? key,
    required this.schoolId,
    required this.eventId,
  }) : super(key: key);

  @override
  _StudentEventDetailScreenState createState() => _StudentEventDetailScreenState();
}

class _StudentEventDetailScreenState extends State<StudentEventDetailScreen> {
  final String? _studentId = FirebaseAuth.instance.currentUser?.uid;
  bool _isLoading = false;

  Future<void> _respondToInvitation(String status) async {
    if (_studentId == null) return;

    setState(() => _isLoading = true);
    try {
      // Usamos la notación de puntos para actualizar un campo dentro de un mapa
      await FirebaseFirestore.instance
          .collection('schools').doc(widget.schoolId)
          .collection('events').doc(widget.eventId)
          .update({'attendeeStatus.${_studentId}': status});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Respuesta enviada: ${status[0].toUpperCase()}${status.substring(1)}'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al enviar respuesta: ${e.toString()}')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalles del Evento'),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('schools').doc(widget.schoolId).collection('events').doc(widget.eventId).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          if (!snapshot.data!.exists) return const Center(child: Text('Este evento ya no existe.'));

          final event = EventModel.fromFirestore(snapshot.data!);
          final myStatus = event.attendeeStatus[_studentId] ?? 'Invitado';

          return AbsorbPointer(
            absorbing: _isLoading,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(event.title, style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 8),
                  if (event.description.isNotEmpty)
                    Text(event.description, style: Theme.of(context).textTheme.bodyLarge),
                  const Divider(height: 32),
                  _buildInfoRow(context, icon: Icons.calendar_today, title: 'Fecha', subtitle: DateFormat('EEEE dd MMM, yyyy', 'es_ES').format(event.date)),
                  _buildInfoRow(context, icon: Icons.access_time, title: 'Hora', subtitle: '${event.startTime.format(context)} - ${event.endTime.format(context)}'),
                  if (event.location.isNotEmpty) _buildInfoRow(context, icon: Icons.location_on, title: 'Ubicación', subtitle: event.location),
                  if (event.cost > 0) _buildInfoRow(context, icon: Icons.payment, title: 'Costo', subtitle: '${event.cost.toStringAsFixed(2)} ${event.currency}'),
                  const Divider(height: 32),

                  Card(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Text('Tu Respuesta: ${myStatus[0].toUpperCase()}${myStatus.substring(1)}', style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 16),
                          if (_isLoading)
                            const CircularProgressIndicator()
                          else
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () => _respondToInvitation('confirmado'),
                                  icon: const Icon(Icons.check),
                                  label: const Text('Confirmar'),
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                ),
                                ElevatedButton.icon(
                                  onPressed: () => _respondToInvitation('rechazado'),
                                  icon: const Icon(Icons.close),
                                  label: const Text('Rechazar'),
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, {required IconData icon, required String title, required String subtitle}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Theme.of(context).primaryColor, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(subtitle, style: const TextStyle(fontSize: 16)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
