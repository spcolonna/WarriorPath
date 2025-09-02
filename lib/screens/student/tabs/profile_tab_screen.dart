import 'package:flutter/material.dart';

class StudentProfileTabScreen extends StatelessWidget {
  final String memberId; // 1. Añadimos la variable para el ID del miembro

  // 2. Actualizamos el constructor
  const StudentProfileTabScreen({
    Key? key,
    required this.memberId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mi Perfil')),
      // Ahora puedes usar el memberId para buscar y editar los datos del usuario
      body: const Center(child: Text('Aquí editarás tu perfil y datos de emergencia.')),
    );
  }
}
