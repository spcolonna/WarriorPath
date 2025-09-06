import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:warrior_path/models/event_model.dart';
import 'package:warrior_path/screens/teacher/events/add_edit_event_screen.dart';
import 'package:warrior_path/screens/teacher/events/invite_students_screen.dart';

class EventDetailScreen extends StatelessWidget {
  final String schoolId;
  final String eventId;

  const EventDetailScreen({Key? key, required this.schoolId, required this.eventId}) : super(key: key);

  Future<void> _deleteEvent(BuildContext context) async {
    final bool didConfirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: const Text('¿Estás seguro de que quieres eliminar este evento permanentemente? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    ) ?? false;

    if (didConfirm && context.mounted) {
      try {
        await FirebaseFirestore.instance
            .collection('schools').doc(schoolId)
            .collection('events').doc(eventId)
            .delete();

        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Evento eliminado.'), backgroundColor: Colors.green));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al eliminar: ${e.toString()}')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('schools').doc(schoolId).collection('events').doc(eventId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return Scaffold(appBar: AppBar(), body: const Center(child: CircularProgressIndicator()));
        if (!snapshot.data!.exists) {
          // Si el evento fue eliminado, cerramos esta pantalla
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (Navigator.canPop(context)) Navigator.pop(context);
          });
          return Scaffold(appBar: AppBar(), body: const Center(child: Text('Este evento ya no existe.')));
        }

        final event = EventModel.fromFirestore(snapshot.data!);

        return Scaffold(
          appBar: AppBar(
            title: Text(event.title),
            actions: [
              IconButton(icon: const Icon(Icons.edit), onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (c) => AddEditEventScreen(schoolId: schoolId, event: event)))),
              IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => _deleteEvent(context)),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(event.description, style: Theme.of(context).textTheme.bodyLarge),
              const Divider(height: 32),
              _buildInfoTile(icon: Icons.calendar_today, title: 'Fecha', subtitle: DateFormat('EEEE dd MMM, yyyy', 'es_ES').format(event.date)),
              _buildInfoTile(icon: Icons.access_time, title: 'Hora', subtitle: '${event.startTime.format(context)} - ${event.endTime.format(context)}'),
              if(event.location.isNotEmpty) _buildInfoTile(icon: Icons.location_on, title: 'Ubicación', subtitle: event.location),
              if(event.cost > 0) _buildInfoTile(icon: Icons.payment, title: 'Costo', subtitle: '${event.cost.toStringAsFixed(2)} ${event.currency}'),
              const Divider(height: 32),
              Text('Asistentes (${event.attendeeStatus.length}/${event.invitedStudentIds.length})', style: Theme.of(context).textTheme.titleLarge),
              _buildAttendeesList(context, event),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (c) => InviteStudentsScreen(schoolId: schoolId, eventId: eventId, alreadyInvitedIds: event.invitedStudentIds)));
            },
            label: const Text('Gestionar Invitados'),
            icon: const Icon(Icons.person_add),
          ),
        );
      },
    );
  }

  Widget _buildInfoTile({required IconData icon, required String title, required String subtitle}) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 16)),
    );
  }

  Widget _buildAttendeesList(BuildContext context, EventModel event) {
    if (event.invitedStudentIds.isEmpty) {
      return const Padding(padding: EdgeInsets.all(16.0), child: Center(child: Text('Aún no has invitado a ningún alumno.')));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('schools').doc(schoolId).collection('members').where(FieldPath.documentId, whereIn: event.invitedStudentIds).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final studentDocs = snapshot.data!.docs;
        return Column(
          children: studentDocs.map((doc) {
            final status = event.attendeeStatus[doc.id] ?? 'Invitado';
            Icon statusIcon;
            switch(status) {
              case 'confirmado': statusIcon = const Icon(Icons.check_circle, color: Colors.green); break;
              case 'rechazado': statusIcon = const Icon(Icons.cancel, color: Colors.red); break;
              default: statusIcon = const Icon(Icons.help_outline, color: Colors.orange);
            }
            return ListTile(
              leading: statusIcon,
              title: Text(doc['displayName']),
              subtitle: Text(status[0].toUpperCase() + status.substring(1)),
            );
          }).toList(),
        );
      },
    );
  }
}
