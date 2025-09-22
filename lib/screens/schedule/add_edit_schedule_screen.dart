import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

class AddEditScheduleScreen extends StatefulWidget {
  final String schoolId;
  const AddEditScheduleScreen({super.key, required this.schoolId});

  @override
  _AddEditScheduleScreenState createState() => _AddEditScheduleScreenState();
}

class _AddEditScheduleScreenState extends State<AddEditScheduleScreen> {
  late AppLocalizations l10n;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    l10n = AppLocalizations.of(context);
    super.didChangeDependencies();
    _dayLabels = [
      l10n.monday[0], l10n.tuesday[0], l10n.wednesday[0], l10n.thursday[0],
      l10n.friday[0], l10n.saturday[0], l10n.sunday[0]
    ];
  }

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  bool _isLoading = false;

  final Map<int, bool> _selectedDays = {
    1: false, 2: false, 3: false, 4: false, 5: false, 6: false, 7: false,
  };
  late final List<String> _dayLabels;

  // --- CAMBIO: Variables para manejar las disciplinas ---
  late Future<List<QueryDocumentSnapshot>> _disciplinesFuture;
  String? _selectedDisciplineId;

  @override
  void initState() {
    super.initState();
    // Cargamos las disciplinas al iniciar la pantalla
    _disciplinesFuture = _fetchDisciplines();
  }

  Future<List<QueryDocumentSnapshot>> _fetchDisciplines() async {
    final disciplinesSnapshot = await FirebaseFirestore.instance
        .collection('schools')
        .doc(widget.schoolId)
        .collection('disciplines')
        .get();
    return disciplinesSnapshot.docs;
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  Future<void> _saveSchedule() async {
    final activeDays = _selectedDays.entries.where((d) => d.value).map((d) => d.key).toList();

    if (_titleController.text.trim().isEmpty || _startTime == null || _endTime == null || activeDays.isEmpty || _selectedDisciplineId == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.pleaseFillAllFields)));
      return;
    }

    if (_endTime!.hour < _startTime!.hour || (_endTime!.hour == _startTime!.hour && _endTime!.minute <= _startTime!.minute)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.endTimeAfterStartTimeError)));
      return;
    }

    setState(() { _isLoading = true; });

    try {
      final batch = FirebaseFirestore.instance.batch();
      final scheduleCollection = FirebaseFirestore.instance.collection('schools').doc(widget.schoolId).collection('classSchedules');

      for (final day in activeDays) {
        final newScheduleDoc = scheduleCollection.doc();
        batch.set(newScheduleDoc, {
          'title': _titleController.text.trim(),
          'dayOfWeek': day,
          'startTime': '${_startTime!.hour.toString().padLeft(2, '0')}:${_startTime!.minute.toString().padLeft(2, '0')}',
          'endTime': '${_endTime!.hour.toString().padLeft(2, '0')}:${_endTime!.minute.toString().padLeft(2, '0')}',
          // --- CAMBIO: Guardamos el ID de la disciplina seleccionada ---
          'disciplineId': _selectedDisciplineId,
        });
      }

      await batch.commit();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.scheduleSavedSuccess), backgroundColor: Colors.green));
      Navigator.of(context).pop();

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.saveError(e.toString()))));
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.addSchedule),
      ),
      body: AbsorbPointer(
        absorbing: _isLoading,
        child: FutureBuilder<List<QueryDocumentSnapshot>>(
          future: _disciplinesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('Primero debes crear disciplinas en tu escuela.'));
            }

            final disciplines = snapshot.data!;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form( // Añadimos un Form para la validación
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(labelText: l10n.classTitle, hintText: l10n.classTitleExample),
                      validator: (value) => (value?.isEmpty ?? true) ? l10n.requiredField : null,
                    ),
                    const SizedBox(height: 16),

                    // --- CAMBIO: Nuevo Dropdown para seleccionar la disciplina ---
                    DropdownButtonFormField<String>(
                      value: _selectedDisciplineId,
                      hint: Text(l10n.selectDiscipline),
                      decoration: InputDecoration(border: const UnderlineInputBorder()),
                      items: disciplines.map((doc) {
                        return DropdownMenuItem(
                          value: doc.id,
                          child: Text(doc['name']),
                        );
                      }).toList(),
                      onChanged: (value) => setState(() => _selectedDisciplineId = value),
                      validator: (value) => value == null ? l10n.requiredField : null,
                    ),
                    const SizedBox(height: 24),

                    Text(l10n.daysOfTheWeek, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8.0,
                      children: List.generate(7, (index) {
                        return FilterChip(
                          label: Text(_dayLabels[index]),
                          selected: _selectedDays[index + 1]!,
                          onSelected: (bool selected) => setState(() => _selectedDays[index + 1] = selected),
                        );
                      }),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => _selectTime(context, true),
                            child: InputDecorator(
                              decoration: InputDecoration(labelText: l10n.startTime),
                              child: Text(_startTime?.format(context) ?? l10n.select),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: InkWell(
                            onTap: () => _selectTime(context, false),
                            child: InputDecorator(
                              decoration: InputDecoration(labelText: l10n.endTime),
                              child: Text(_endTime?.format(context) ?? l10n.select),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    if (_isLoading)
                      const Center(child: CircularProgressIndicator())
                    else
                      ElevatedButton(
                        onPressed: _saveSchedule,
                        style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                        child: Text(l10n.saveSchedule),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
