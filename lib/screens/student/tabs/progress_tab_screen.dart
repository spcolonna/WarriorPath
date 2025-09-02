import 'package:flutter/material.dart';

class ProgressTabScreen extends StatelessWidget {
  final String schoolId;
  final String memberId; // 1. Añadimos la variable para el ID del miembro

  // 2. Actualizamos el constructor para que reciba ambos IDs
  const ProgressTabScreen({
    Key? key,
    required this.schoolId,
    required this.memberId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mi Progreso')),
      // Ahora puedes usar ambos IDs para buscar la información de progreso
      body: Center(child: Text('Aquí verás tu nivel, técnicas y exámenes.')),
    );
  }
}
