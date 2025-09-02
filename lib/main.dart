import 'package:provider/provider.dart';
import 'package:warrior_path/providers/theme_provider.dart';
import 'package:warrior_path/services/remote_config_service.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'package:warrior_path/screens/WelcomeScreen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  final remoteConfigService = await RemoteConfigService.getInstance();
  await remoteConfigService.fetchAndActivate();

  // --- LÍNEA AÑADIDA AQUÍ ---
  // Carga los datos de formato para el idioma español (para meses, etc.)
  await initializeDateFormatting('es_ES', null);
  // -------------------------

  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Warrior Path',
          theme: ThemeData(
            primarySwatch: Colors.blue,
            primaryColor: themeProvider.theme.primaryColor,
            appBarTheme: AppBarTheme(
              backgroundColor: themeProvider.theme.primaryColor,
            ),
            floatingActionButtonTheme: FloatingActionButtonThemeData(
              backgroundColor: themeProvider.theme.accentColor,
            ),
            // ... puedes configurar más colores y estilos aquí
          ),
          home: const WelcomeScreen(),
        );
      },
    );
  }
}
