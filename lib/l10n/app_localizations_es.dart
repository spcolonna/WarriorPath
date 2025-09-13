// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appName => 'Warrior Path';

  @override
  String get appSlogan => 'Sé un guerrero, crea tu camino';

  @override
  String get emailLabel => 'Correo Electrónico';

  @override
  String get loginButton => 'Iniciar Sesión';

  @override
  String get createAccountButton => 'Crear Cuenta';

  @override
  String get forgotPasswordLink => '¿Olvidaste tu contraseña?';

  @override
  String get profileErrorTitle => 'Error de Perfil';

  @override
  String get profileErrorContent =>
      'No se pudo cargar tu perfil. Intenta de nuevo.';

  @override
  String get accessDeniedTitle => 'Acceso Denegado';

  @override
  String get accessDeniedContent =>
      'No tienes un rol activo en ninguna escuela.';

  @override
  String get loginErrorTitle => 'Error de Login';

  @override
  String get loginErrorUserNotFound =>
      'No se encontró un usuario con ese correo electrónico.';

  @override
  String get loginErrorWrongPassword => 'La contraseña es incorrecta.';

  @override
  String get loginErrorInvalidCredential => 'Las credenciales son incorrectas.';

  @override
  String get unexpectedError => 'Ocurrió un error inesperado.';

  @override
  String get registrationErrorTitle => 'Error de Registro';

  @override
  String get registrationErrorContent =>
      'No se pudo completar el registro. El correo puede ya estar en uso o la contraseña es muy débil.';

  @override
  String get errorTitle => 'Error';

  @override
  String genericErrorContent(String errorDetails) {
    return 'Ocurrió un error: $errorDetails';
  }

  @override
  String get language => 'Idioma';

  @override
  String get ok => 'Ok';

  @override
  String welcomeTitle(String userName) {
    return '¡Bienvenido, $userName!';
  }

  @override
  String get teacher => 'Maestro';

  @override
  String get sessionError => 'Error: Sesión no válida.';

  @override
  String get noSchedulerClass => 'No hay clases programadas para hoy.';

  @override
  String get choseClass => 'Seleccionar Clase';

  @override
  String get todayClass => 'Clases de Hoy';

  @override
  String get takeAssistance => 'Tomar Asistencia';

  @override
  String get loading => 'Cargando...';

  @override
  String get activeStudents => 'Alumnos Activos';

  @override
  String get pendingApplication => 'Solicitudes Pendientes';
}
