import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:warrior_path/models/event_model.dart';
import 'package:warrior_path/screens/teacher/events/invite_students_screen.dart';

class AddEditEventScreen extends StatefulWidget {
  final String schoolId;
  final EventModel? event;

  const AddEditEventScreen({Key? key, required this.schoolId, this.event}) : super(key: key);

  @override
  State<AddEditEventScreen> createState() => _AddEditEventScreenState();
}

class _AddEditEventScreenState extends State<AddEditEventScreen> {
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

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final event = widget.event!;
      _titleController.text = event.title;
      _descriptionController.text = event.description;
      _locationController.text = event.location;
      _costController.text = event.cost.toString();
      _selectedDate = event.date;
      _startTime = event.startTime;
      _endTime = event.endTime;
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
    DateTime? pickedDate = await showDatePicker(context: context, initialDate: _selectedDate ?? DateTime.now(), firstDate: DateTime.now().subtract(const Duration(days: 365)), lastDate: DateTime(DateTime.now().year + 5));
    if (pickedDate != null) setState(() => _selectedDate = pickedDate);
  }

  Future<void> _pickTime(bool isStart) async {
    TimeOfDay? pickedTime = await showTimePicker(context: context, initialTime: (isStart ? _startTime : _endTime) ?? TimeOfDay.now());
    if (pickedTime != null) {
      setState(() => isStart ? _startTime = pickedTime : _endTime = pickedTime);
    }
  }

  Future<void> _saveEvent() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null || _startTime == null || _endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Por favor, completa la fecha y las horas.')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('No autenticado');

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
      );

      final eventsRef = FirebaseFirestore.instance.collection('schools').doc(widget.schoolId).collection('events');

      if (_isEditing) {
        await eventsRef.doc(eventData.id).update(eventData.toJson());
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Evento actualizado.'), backgroundColor: Colors.green));
          Navigator.of(context).pop();
        }
      } else {
        final newDoc = await eventsRef.add(eventData.toJson());
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('¡Evento creado! Ahora puedes invitar a los alumnos.'), backgroundColor: Colors.green));
          // Reemplazamos la pantalla actual por la de invitar alumnos
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (c) => InviteStudentsScreen(schoolId: widget.schoolId, eventId: newDoc.id, alreadyInvitedIds: const [])),
          );
        }
      }

    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al crear el evento: ${e.toString()}')));
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Editar Evento' : 'Crear Nuevo Evento')),
      body: AbsorbPointer(
        absorbing: _isLoading,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(controller: _titleController, decoration: const InputDecoration(labelText: 'Título del Evento *'), validator: (v) => v!.isEmpty ? 'Campo requerido' : null),
                const SizedBox(height: 16),
                TextFormField(controller: _descriptionController, decoration: const InputDecoration(labelText: 'Descripción'), maxLines: 3),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: Text(_selectedDate == null ? 'Seleccionar Fecha *' : DateFormat('dd/MM/yyyy', 'es_ES').format(_selectedDate!)),
                  onTap: _pickDate,
                ),
                Row(children: [
                  Expanded(child: ListTile(leading: const Icon(Icons.access_time), title: Text(_startTime == null ? 'Hora Inicio *' : _startTime!.format(context)), onTap: () => _pickTime(true))),
                  Expanded(child: ListTile(leading: const Icon(Icons.access_time_filled), title: Text(_endTime == null ? 'Hora Fin *' : _endTime!.format(context)), onTap: () => _pickTime(false))),
                ]),
                const SizedBox(height: 16),
                TextFormField(controller: _locationController, decoration: const InputDecoration(labelText: 'Ubicación (Opcional)')),
                const SizedBox(height: 16),
                TextFormField(controller: _costController, decoration: const InputDecoration(labelText: 'Costo (Opcional)'), keyboardType: TextInputType.number),
                const SizedBox(height: 32),
                if (_isLoading) const Center(child: CircularProgressIndicator()) else ElevatedButton(
                  onPressed: _saveEvent,
                  child: Text(_isEditing ? 'Guardar Cambios' : 'Guardar y Continuar'),
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
