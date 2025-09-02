import 'package:flutter/material.dart';

class StudentProfileTabScreen extends StatelessWidget {
  const StudentProfileTabScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mi Perfil')),
      body: const Center(child: Text('Aquí editarás tu perfil y datos de emergencia.')),
    );
  }
}
