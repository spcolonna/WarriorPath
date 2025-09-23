import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:warrior_path/models/discipline_model.dart';
import 'package:warrior_path/models/event_model.dart';
import 'package:warrior_path/screens/teacher/events/invite_students_screen.dart';

import '../../../l10n/app_localizations.dart';

class AddEditEventScreen extends StatefulWidget {
  final String schoolId;
  final EventModel? event;

  const AddEditEventScreen({Key? key, required this.schoolId, this.event}) : super(key: key);

  @override
  State<AddEditEventScreen> createState() => _AddEditEventScreenState();
}

class _AddEditEventScreenState extends State<AddEditEventScreen> {
  late AppLocalizations l10n;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    l10n = AppLocalizations.of(context);
  }

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _costController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  bool _isLoading = false;
  bool get _isEditing => widget.event != null;

  List<DisciplineModel> _allDisciplines = [];
  Set<String> _selectedDisciplineIds = {};

  @override
  void initState() {
    super.initState();
    _fetchDisciplines();

    if (_isEditing) {
      final event = widget.event!;
      _titleController.text = event.title;
      _descriptionController.text = event.description;
      _locationController.text = event.location;
      _costController.text = event.cost.toString();
      _selectedDate = event.date;
      _startTime = event.startTime;
      _endTime = event.endTime;
      _selectedDisciplineIds = Set<String>.from(event.disciplineIds);
    }
  }

  Future<void> _fetchDisciplines() async {
    final disciplinesSnapshot = await FirebaseFirestore.instance
        .collection('schools').doc(widget.schoolId)
        .collection('disciplines').where('isActive', isEqualTo: true).get();

    if (mounted) {
      setState(() {
        _allDisciplines = disciplinesSnapshot.docs.map((doc) => DisciplineModel.fromFirestore(doc)).toList();
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _costController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    DateTime? pickedDate = await showDatePicker(context: context, initialDate: _selectedDate ?? DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime(DateTime.now().year + 5));
    if (pickedDate != null) setState(() => _selectedDate = pickedDate);
  }

  Future<void> _pickTime(bool isStart) async {
    TimeOfDay? pickedTime = await showTimePicker(context: context, initialTime: (isStart ? _startTime : _endTime) ?? TimeOfDay.now());
    if (pickedTime != null) setState(() => isStart ? _startTime = pickedTime : _endTime = pickedTime);
  }

  Future<void> _saveEvent() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null || _startTime == null || _endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.pleaseCompleteDateTime)));
      return;
    }
    // --- CAMBIO: Validamos que se haya elegido al menos una disciplina ---
    if (_selectedDisciplineIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.selectAtLeastOneDiscipline)));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception(l10n.notAuthenticatedUser);

      final eventData = EventModel(
        id: widget.event?.id,
        title: _titleController.text,
        description: _descriptionController.text,
        date: _selectedDate!,
        startTime: _startTime!,
        endTime: _endTime!,
        location: _locationController.text,
        cost: double.tryParse(_costController.text) ?? 0.0,
        createdBy: widget.event?.createdBy ?? user.uid,
        invitedStudentIds: widget.event?.invitedStudentIds ?? [],
        attendeeStatus: widget.event?.attendeeStatus ?? {},
        disciplineIds: _selectedDisciplineIds.toList(), // <-- CAMBIO
      );

      final eventsRef = FirebaseFirestore.instance.collection('schools').doc(widget.schoolId).collection('events');

      if (_isEditing) {
        await eventsRef.doc(eventData.id).update(eventData.toJson());
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.eventUpdated), backgroundColor: Colors.green));
          Navigator.of(context).pop();
        }
      } else {
        final newDoc = await eventsRef.add(eventData.toJson());
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.eventCreatedInviteStudents), backgroundColor: Colors.green));
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (c) => InviteStudentsScreen(schoolId: widget.schoolId, eventId: newDoc.id, alreadyInvitedIds: const [])),
          );
        }
      }

    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.eventCreationError(e.toString()))));
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? l10n.editEvent : l10n.createNewEvent)),
      body: AbsorbPointer(
        absorbing: _isLoading,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(controller: _titleController, decoration: InputDecoration(labelText: l10n.eventTitle), validator: (v) => v!.isEmpty ? l10n.requiredField : null),
                const SizedBox(height: 16),

                // --- CAMBIO: Nueva sección para seleccionar disciplinas ---
                Text(l10n.involvedDisciplines, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                if (_allDisciplines.isEmpty)
                  const Center(child: CircularProgressIndicator())
                else
                  Wrap(
                    spacing: 8.0,
                    children: _allDisciplines.map((discipline) {
                      return FilterChip(
                        label: Text(discipline.name),
                        selected: _selectedDisciplineIds.contains(discipline.id),
                        onSelected: (bool selected) {
                          setState(() {
                            if (selected) {
                              _selectedDisciplineIds.add(discipline.id!);
                            } else {
                              _selectedDisciplineIds.remove(discipline.id!);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                const SizedBox(height: 16),

                TextFormField(controller: _descriptionController, decoration: InputDecoration(labelText: l10n.description), maxLines: 3),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today),
                  title: Text(_selectedDate == null ? l10n.selectDate : DateFormat('dd/MM/yyyy', 'es_ES').format(_selectedDate!)),
                  onTap: _pickDate,
                ),
                Row(children: [
                  Expanded(child: ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.access_time), title: Text(_startTime == null ? l10n.startTime : _startTime!.format(context)), onTap: () => _pickTime(true))),
                  Expanded(child: ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.access_time_filled), title: Text(_endTime == null ? l10n.endTime : _endTime!.format(context)), onTap: () => _pickTime(false))),
                ]),
                const SizedBox(height: 16),
                TextFormField(controller: _locationController, decoration: InputDecoration(labelText: l10n.locationOptional)),
                const SizedBox(height: 16),
                TextFormField(controller: _costController, decoration: InputDecoration(labelText: l10n.costOptional), keyboardType: TextInputType.number),
                const SizedBox(height: 32),
                if (_isLoading) const Center(child: CircularProgressIndicator()) else ElevatedButton(
                  onPressed: _saveEvent,
                  child: Text(_isEditing ? l10n.saveChanges : l10n.saveAndContinue),
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
