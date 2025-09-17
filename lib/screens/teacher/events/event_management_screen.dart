import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:warrior_path/screens/teacher/events/add_edit_event_screen.dart';

import '../../../l10n/app_localizations.dart';
import 'event_detail_screen.dart';

class EventManagementScreen extends StatefulWidget {
  final String schoolId;
  const EventManagementScreen({Key? key, required this.schoolId}) : super(key: key);

  @override
  State<EventManagementScreen> createState() => _EventManagementScreenState();
}

class _EventManagementScreenState extends State<EventManagementScreen> with SingleTickerProviderStateMixin {
  late AppLocalizations l10n;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    l10n = AppLocalizations.of(context);
  }

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.manageEvents),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'Próximos'), Tab(text: 'Pasados')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildEventsList(isUpcoming: true),
          _buildEventsList(isUpcoming: false),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => AddEditEventScreen(schoolId: widget.schoolId)),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEventsList({required bool isUpcoming}) {
    final now = Timestamp.now();
    Query query = FirebaseFirestore.instance
        .collection('schools').doc(widget.schoolId).collection('events');

    if (isUpcoming) {
      query = query.where('eventDate', isGreaterThanOrEqualTo: now).orderBy('eventDate', descending: false);
    } else {
      query = query.where('eventDate', isLessThan: now).orderBy('eventDate', descending: true);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return Center(child: Text('No hay eventos ${isUpcoming ? 'próximos' : 'pasados'}.'));

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final eventDoc = snapshot.data!.docs[index];
            final data = eventDoc.data() as Map<String, dynamic>;
            final date = (data['eventDate'] as Timestamp).toDate();
            final formattedDate = DateFormat('dd MMM yyyy', 'es_ES').format(date);

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                title: Text(data['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${data['startTime']} - ${data['endTime']}'),
                trailing: Text(formattedDate),
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (c) => EventDetailScreen(schoolId: widget.schoolId, eventId: eventDoc.id)));
                },
              ),
            );
          },
        );
      },
    );
  }
}
