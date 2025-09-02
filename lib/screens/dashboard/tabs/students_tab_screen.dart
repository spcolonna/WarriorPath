import 'package:flutter/material.dart';

class StudentsTabScreen extends StatelessWidget {
  final String schoolId;
  const StudentsTabScreen({Key? key, required this.schoolId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Alumnos')),
      body: Center(child: Text('Gestionar alumnos para la escuela con ID: $schoolId')),
    );
  }
}
