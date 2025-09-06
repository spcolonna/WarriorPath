import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class InviteStudentsScreen extends StatefulWidget {
  final String schoolId;
  final String eventId;
  final List<String> alreadyInvitedIds;

  const InviteStudentsScreen({
    Key? key,
    required this.schoolId,
    required this.eventId,
    required this.alreadyInvitedIds,
  }) : super(key: key);

  @override
  _InviteStudentsScreenState createState() => _InviteStudentsScreenState();
}

class _InviteStudentsScreenState extends State<InviteStudentsScreen> {
  late Set<String> _selectedStudentIds;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedStudentIds = Set<String>.from(widget.alreadyInvitedIds);
  }

  Future<void> _saveInvitations() async {
    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance
          .collection('schools').doc(widget.schoolId)
          .collection('events').doc(widget.eventId)
          .update({'invitedStudentIds': _selectedStudentIds.toList()});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invitaciones guardadas.'), backgroundColor: Colors.green));
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Invitar Alumnos')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('schools').doc(widget.schoolId).collection('members').where('status', isEqualTo: 'active').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final students = snapshot.data!.docs;

          return ListView.builder(
            itemCount: students.length,
            itemBuilder: (context, index) {
              final studentDoc = students[index];
              final isSelected = _selectedStudentIds.contains(studentDoc.id);
              return CheckboxListTile(
                title: Text(studentDoc['displayName']),
                value: isSelected,
                onChanged: (bool? value) {
                  setState(() {
                    if (value == true) {
                      _selectedStudentIds.add(studentDoc.id);
                    } else {
                      _selectedStudentIds.remove(studentDoc.id);
                    }
                  });
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isLoading ? null : _saveInvitations,
        label: const Text('Guardar Invitaciones'),
        icon: const Icon(Icons.save),
      ),
    );
  }
}
