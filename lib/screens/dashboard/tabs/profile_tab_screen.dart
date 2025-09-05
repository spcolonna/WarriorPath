import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:warrior_path/screens/WelcomeScreen.dart';
import 'package:warrior_path/screens/role_selector_screen.dart';
import 'package:warrior_path/screens/student/school_search_screen.dart';
import 'package:warrior_path/screens/wizard_create_school_screen.dart';

import '../../teacher/edit_teacher_profile_screen.dart';

class ProfileTabScreen extends StatelessWidget {
  const ProfileTabScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil y Acciones'),
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
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Editar mi Perfil'),
            subtitle: const Text('Actualiza tu nombre, foto o contraseña.'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const EditTeacherProfileScreen()),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.swap_horiz),
            title: const Text('Cambiar de Perfil/Escuela'),
            subtitle: const Text('Accede a tus otros roles o escuelas.'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const RoleSelectorScreen()),
              );
            },
          ),
          const Divider(),

          // --- 2. TARJETA AÑADIDA AQUÍ ---
          Card(
            elevation: 2,
            child: ListTile(
              leading: Icon(Icons.search, color: Theme.of(context).primaryColor),
              title: const Text('Inscribirme en otra Escuela'),
              subtitle: const Text('Únete a otra comunidad como alumno.'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const SchoolSearchScreen()),
                );
              },
            ),
          ),
          const SizedBox(height: 8), // Espacio entre las tarjetas

          Card(
            elevation: 2,
            child: ListTile(
              leading: Icon(Icons.add_business, color: Theme.of(context).primaryColor),
              title: const Text('Crear una Nueva Escuela'),
              subtitle: const Text('Expande tu legado o abre una nueva sucursal.'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const WizardCreateSchoolScreen()),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
