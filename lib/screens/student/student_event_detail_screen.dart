import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:warrior_path/models/event_model.dart';

import '../../l10n/app_localizations.dart';

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
  late AppLocalizations l10n;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    l10n = AppLocalizations.of(context);
  }

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
          SnackBar(content: Text(l10n.responseSent(status[0].toUpperCase() + status.substring(1))), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.errorSendingResponse(e.toString()))));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.eventDetails),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('schools').doc(widget.schoolId).collection('events').doc(widget.eventId).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          if (!snapshot.data!.exists) return Center(child: Text(l10n.eventNoLongerExists));

          final event = EventModel.fromFirestore(snapshot.data!);
          final myStatus = event.attendeeStatus[_studentId] ?? l10n.invited;

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
                  _buildInfoRow(context, icon: Icons.calendar_today, title: l10n.date, subtitle: DateFormat('EEEE dd MMM, yyyy', 'es_ES').format(event.date)),
                  _buildInfoRow(context, icon: Icons.access_time, title: l10n.time, subtitle: '${event.startTime.format(context)} - ${event.endTime.format(context)}'),
                  if (event.location.isNotEmpty) _buildInfoRow(context, icon: Icons.location_on, title: l10n.location, subtitle: event.location),
                  if (event.cost > 0) _buildInfoRow(context, icon: Icons.payment, title: l10n.cost, subtitle: '${event.cost.toStringAsFixed(2)} ${event.currency}'),
                  const Divider(height: 32),

                  Card(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Text(l10n.yourAnswer(myStatus[0].toUpperCase() + myStatus.substring(1)), style: Theme.of(context).textTheme.titleMedium),
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
                                  label: Text(l10n.confirm),
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                ),
                                ElevatedButton.icon(
                                  onPressed: () => _respondToInvitation('rechazado'),
                                  icon: const Icon(Icons.close),
                                  label: Text(l10n.reject),
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
