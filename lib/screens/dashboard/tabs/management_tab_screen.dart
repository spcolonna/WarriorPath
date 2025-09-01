import 'package:flutter/material.dart';

class ManagementTabScreen extends StatelessWidget {
  const ManagementTabScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gestión de la Escuela')),
      body: const Center(child: Text('Aquí se configurarán los horarios, niveles, etc.')),
    );
  }
}
