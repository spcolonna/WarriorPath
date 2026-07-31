import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:provider/provider.dart';
import 'package:warrior_path/providers/locale_provider.dart';
import 'package:warrior_path/providers/session_provider.dart';
import 'package:warrior_path/providers/theme_provider.dart';
import 'package:warrior_path/services/local_notification_service.dart';
import 'package:warrior_path/services/notification_service.dart';
import 'package:warrior_path/services/remote_config_service.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'firebase_options.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:warrior_path/widgets/ad_banner_widget.dart';
import 'package:warrior_path/screens/app_splash_screen.dart';

import 'l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // App Check: rechaza requests que no provengan de la app real (frena
    // bots/scripts). En debug usa el provider de debug (requiere registrar el
    // token de debug en la consola); en release usa App Attest (iOS) y Play
    // Integrity (Android).
    try {
      await FirebaseAppCheck.instance.activate(
        appleProvider:
            kDebugMode ? AppleProvider.debug : AppleProvider.appAttest,
        androidProvider:
            kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
      );
    } catch (e) {
      print('AppCheck error: $e');
    }

    MobileAds.instance.initialize();
    
    try {
      await NotificationService().initialize();
    } catch (e) {
      print('NotificationService error: $e');
    }

    try {
      await LocalNotificationService.initialize();
    } catch (e) {
      print('LocalNotificationService error: $e');
    }
    
    try {
      final remoteConfigService = await RemoteConfigService.getInstance();
      await remoteConfigService.fetchAndActivate();
    } catch (e) {
      print('RemoteConfig error: $e');
    }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ChangeNotifierProvider(create: (context) => SessionProvider()),
        ChangeNotifierProvider(create: (context) => LocaleProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Accessor SEGURO: nunca lanza aunque Remote Config no se haya inicializado
    // (evita el crash de arranque en release). Cae a los defaults (false).
    final bool showBannerAd = RemoteConfigService.boolOf('show_banner_ad');
    final bool showLanding = RemoteConfigService.boolOf('show_landing_screen');

    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Consumer<LocaleProvider>(
          builder: (context, localeProvider, child) {
            return MaterialApp(
              title: 'Warrior Path',
              // Permite navegar al tocar una notificación, desde fuera del
              // árbol de widgets.
              navigatorKey: appNavigatorKey,
              theme: ThemeData(
                colorScheme: ColorScheme.fromSeed(
                  seedColor: themeProvider.theme.primaryColor,
                  primary: themeProvider.theme.primaryColor,
                  secondary: themeProvider.theme.accentColor,
                ),
                primaryColor: themeProvider.theme.primaryColor,
                appBarTheme: AppBarTheme(
                  backgroundColor: themeProvider.theme.primaryColor,
                  foregroundColor: Colors.white,
                  titleTextStyle: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                tabBarTheme: const TabBarThemeData(
                  labelColor: Colors.white,
                  unselectedLabelColor: Color(0x8DFFFFFF),
                  indicatorColor: Colors.white,
                  indicatorSize: TabBarIndicatorSize.tab,
                ),
                floatingActionButtonTheme: FloatingActionButtonThemeData(
                  backgroundColor: themeProvider.theme.accentColor,
                ),
              ),

              // --- CAMBIO: Conectamos MaterialApp con el sistema de i18n ---
              locale: localeProvider.locale, // 1. Usa el locale del provider
              localizationsDelegates: AppLocalizations.localizationsDelegates, // 2. Usa los delegados generados
              supportedLocales: AppLocalizations.supportedLocales, // 3. Usa los locales generados

              home: AppSplashScreen(showLanding: showLanding),
              builder: (context, navigator) {
                final content = Column(
                  children: [
                    Expanded(child: navigator!),
                    if (showBannerAd) const AdBannerWidget(),
                  ],
                );
                if (!kIsWeb) return content;
                return ColoredBox(
                  color: Theme.of(context).colorScheme.surfaceContainerLow,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 920),
                      child: ClipRect(child: content),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
