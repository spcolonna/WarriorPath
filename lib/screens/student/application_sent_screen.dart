import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:warrior_path/screens/WelcomeScreen.dart';
import 'package:warrior_path/screens/student/school_search_screen.dart'; // 1. Importar la pantalla de búsqueda

class ApplicationSentScreen extends StatelessWidget {
  final String schoolName;
  const ApplicationSentScreen({Key? key, required this.schoolName}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Solicitud Enviada'),
        automaticallyImplyLeading: false, // Evita la flecha de "Atrás"
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(
                Icons.check_circle_outline,
                color: Colors.green,
                size: 80,
              ),
              const SizedBox(height: 24),
              Text(
                '¡Felicitaciones!',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Tu solicitud para unirte a "$schoolName" ha sido enviada con éxito.',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Recibirás una notificación cuando el maestro a cargo revise tu postulación.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // --- 2. BOTÓN AÑADIDO PARA BUSCAR OTRA ESCUELA ---
              TextButton.icon(
                icon: const Icon(Icons.search),
                label: const Text('¿Te equivocaste? Busca otra escuela'),
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      // Lo llevamos de vuelta al buscador de escuelas
                      builder: (context) => const SchoolSearchScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),

              ElevatedButton.icon(
                icon: const Icon(Icons.logout),
                label: const Text('Cerrar Sesión'),
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  if (context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => const WelcomeScreen()),
                          (route) => false,
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
