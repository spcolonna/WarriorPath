import 'package:flutter/material.dart';

class ProfileTabScreen extends StatelessWidget {
  const ProfileTabScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mi Perfil')),
      body: const Center(child: Text('Aquí irá el perfil del maestro y el selector de rol.')),
    );
  }
}
