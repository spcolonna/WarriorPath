import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:warrior_path/screens/WelcomeScreen.dart';
import 'package:warrior_path/screens/wizard_profile_screen.dart';

import '../../wizard_create_school_screen.dart';

class ProfileTabScreen extends StatelessWidget {
  const ProfileTabScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar Sesión',
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const WelcomeScreen()),
                      (route) => false,
                );
              }
            },
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // En el futuro aquí irán los datos del maestro
          const ListTile(
            leading: Icon(Icons.person),
            title: Text('Editar mi Perfil'),
            subtitle: Text('Actualiza tu nombre, foto o contraseña.'),
          ),
          const Divider(),
          // Aquí podría ir el selector de rol/escuela en el futuro
          const ListTile(
            leading: Icon(Icons.swap_horiz),
            title: Text('Cambiar de Perfil'),
            subtitle: Text('Accede a tus otros roles o escuelas.'),
          ),
          const Divider(),
          // El nuevo botón para crear otra escuela
          Card(
            elevation: 2,
            child: ListTile(
              leading: Icon(Icons.add_business, color: Theme.of(context).primaryColor),
              title: const Text('Crear una Nueva Escuela'),
              subtitle: const Text('Expande tu legado o abre una nueva sucursal.'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const WizardCreateSchoolScreen(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
