import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

class AddEditScheduleScreen extends StatefulWidget {
  final String schoolId;
  // Opcional: podrías pasar un horario existente para editarlo en el futuro
  // final ScheduleItem? scheduleItem;

  const AddEditScheduleScreen({Key? key, required this.schoolId}) : super(key: key);

  @override
  _AddEditScheduleScreenState createState() => _AddEditScheduleScreenState();
}

class _AddEditScheduleScreenState extends State<AddEditScheduleScreen> {
  late AppLocalizations l10n;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    l10n = AppLocalizations.of(context);
  }

  final _titleController = TextEditingController();
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  bool _isLoading = false;

  // Usamos un Map para los días. El int es el dayOfWeek (1-7), bool si está seleccionado.
  final Map<int, bool> _selectedDays = {
    1: false, // Lunes
    2: false, // Martes
    3: false, // Miércoles
    4: false, // Jueves
    5: false, // Viernes
    6: false, // Sábado
    7: false, // Domingo
  };
  final List<String> _dayLabels = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];

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
    if (_titleController.text.trim().isEmpty || _startTime == null || _endTime == null || activeDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Por favor, completa todos los campos requeridos.')));
      return;
    }

    if (_endTime!.hour < _startTime!.hour || (_endTime!.hour == _startTime!.hour && _endTime!.minute <= _startTime!.minute)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('La hora de fin debe ser posterior a la hora de inicio.')));
      return;
    }

    setState(() { _isLoading = true; });

    try {
      final batch = FirebaseFirestore.instance.batch();
      final scheduleCollection = FirebaseFirestore.instance.collection('schools').doc(widget.schoolId).collection('classSchedules');

      // Creamos un documento por CADA día seleccionado
      for (final day in activeDays) {
        final newScheduleDoc = scheduleCollection.doc();
        batch.set(newScheduleDoc, {
          'title': _titleController.text.trim(),
          'dayOfWeek': day,
          'startTime': '${_startTime!.hour.toString().padLeft(2, '0')}:${_startTime!.minute.toString().padLeft(2, '0')}',
          'endTime': '${_endTime!.hour.toString().padLeft(2, '0')}:${_endTime!.minute.toString().padLeft(2, '0')}',
        });
      }

      await batch.commit();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Horario guardado con éxito.')));
      Navigator.of(context).pop();

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.saveError(e.toString()))));
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Título de la Clase', hintText: 'Ej: Niños, Adultos, Kicks'),
              ),
              const SizedBox(height: 24),
              Text('Días de la semana', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8.0,
                children: List.generate(7, (index) {
                  return FilterChip(
                    label: Text(_dayLabels[index]),
                    selected: _selectedDays[index + 1]!,
                    onSelected: (bool selected) {
                      setState(() {
                        _selectedDays[index + 1] = selected;
                      });
                    },
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
                        decoration: const InputDecoration(labelText: 'Hora de Inicio'),
                        child: Text(_startTime?.format(context) ?? l10n.select),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectTime(context, false),
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'Hora de Fin'),
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
                  style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16)
                  ),
                  child: Text(l10n.saveSchedule),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
