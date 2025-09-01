import 'package:flutter/material.dart';

class StudentsTabScreen extends StatelessWidget {
  const StudentsTabScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Alumnos')),
      body: const Center(child: Text('Aquí se gestionarán los alumnos.')),
    );
  }
}
