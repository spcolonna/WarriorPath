import 'package:flutter/material.dart';

class ProgressTabScreen extends StatelessWidget {
  final String schoolId;
  const ProgressTabScreen({Key? key, required this.schoolId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mi Progreso')),
      body: const Center(child: Text('Aquí verás tu nivel, técnicas y exámenes.')),
    );
  }
}
