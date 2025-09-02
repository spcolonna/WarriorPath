import 'package:flutter/material.dart';

class StudentDashboardScreen extends StatelessWidget {
  const StudentDashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Progreso'),
      ),
      body: const Center(
        child: Text(
          '¡Bienvenido, Alumno!\nAquí verás tu perfil y progreso.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
