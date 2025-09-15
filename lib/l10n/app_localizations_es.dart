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
  String get teacherLower => 'maestro';

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

  @override
  String get password => 'Contraseña';

  @override
  String get home => 'Inicio';

  @override
  String get student => 'Alumno';

  @override
  String get studentLower => 'alumno';

  @override
  String get managment => 'Gestión';

  @override
  String get profile => 'Perfil';

  @override
  String get actives => 'Activos';

  @override
  String get pending => 'Pendientes';

  @override
  String get inactives => 'Inactivos';

  @override
  String get general => 'General';

  @override
  String get assistance => 'Asistencia';

  @override
  String get payments => 'Pagos';

  @override
  String get payment => 'Pago';

  @override
  String get progress => 'Progreso';

  @override
  String get technics => 'Técnicas';

  @override
  String get facturation => 'Facturación';

  @override
  String get changeAssignedPlan => 'Cambiar Plan Asignado';

  @override
  String get personalData => 'Datos Personales';

  @override
  String get birdthDate => 'Fecha de Nacimiento';

  @override
  String get gender => 'Sexo';

  @override
  String get years => 'años';

  @override
  String get phone => 'Teléfono';

  @override
  String get emergencyInfo => 'Información de Emergencia';

  @override
  String get contact => 'Contacto';

  @override
  String get medService => 'Servicio Médico';

  @override
  String get medInfo => 'Información Médica';

  @override
  String get noSpecify => 'No especifícado';

  @override
  String get changeRol => 'Cambiar Rol';

  @override
  String get noPayment => 'No hay pagos registrados para este alumno.';

  @override
  String get errorLoadHistory => 'Error al cargar el historial.';

  @override
  String get noRegisterAssitance =>
      'No hay registros de asistencia para este alumno.';

  @override
  String get classRoom => 'Clase';

  @override
  String get removeAssistance => 'Quitar esta asistencia';

  @override
  String get confirm => 'Confirmar';

  @override
  String get removeAssistanceCOnfirmation =>
      '¿Estás seguro de que quieres eliminar esta asistencia del registro del alumno?';

  @override
  String get cancel => 'Cancelar';

  @override
  String get eliminate => 'Eliminar';

  @override
  String get assistanceDelete => 'Asistencia eliminada.';

  @override
  String deleteError(String e) {
    return 'Error al eliminar: $e';
  }

  @override
  String get loadProgressError => 'Error al cargar el progreso.';

  @override
  String get noHistPromotion =>
      'Este alumno no tiene historial de promociones.';

  @override
  String rolUpdatedTo(String rol) {
    return 'Rol actualizado a $rol';
  }

  @override
  String get invalidRegisterPromotion => 'Registro de promoción inválido';

  @override
  String get deleteLevel => 'Nivel Borrado';

  @override
  String promotionTo(String level) {
    return 'Promovido a $level';
  }

  @override
  String get notes => 'Notas';

  @override
  String notesWith(Object notesWith) {
    return 'Notes: $notesWith';
  }

  @override
  String notesValue(String notes) {
    return 'Notas: $notes';
  }

  @override
  String get revertPromotion => 'Revertir Promoción';

  @override
  String get revertThisPromotion => 'Revertir esta promoción';

  @override
  String get confirmReverPromotion =>
      '¿Estás seguro de que quieres eliminar este registro de promoción? \n\nEsto revertirá el nivel actual del alumno a su nivel anterior.';

  @override
  String get yesRevert => 'Sí, Revertir';

  @override
  String get maleGender => 'Masculino';

  @override
  String get femaleGender => 'Femenino';

  @override
  String get otherGender => 'Otro';

  @override
  String get noSpecifyGender => 'Prefiere no decirlo';

  @override
  String get noClassForTHisDay =>
      'No había clases programadas para el día seleccionado.';

  @override
  String classFor(String day) {
    return 'Clases del $day';
  }

  @override
  String get successAssistance => 'Asistencia registrada con éxito.';

  @override
  String saveError(String e) {
    return 'Error al guardar: $e';
  }

  @override
  String get successRevertPromotion => 'Promoción revertida con éxito.';

  @override
  String errorToRevert(String e) {
    return 'Error al revertir: $e';
  }

  @override
  String get registerPayment => 'Registrar Pago';

  @override
  String get payPlan => 'Pago de Plan';

  @override
  String get paySpecial => 'Pago Especial';

  @override
  String get selectPlan => 'Selecciona un plan';

  @override
  String get concept => 'Concepto';

  @override
  String get amount => 'Monto';

  @override
  String get savePayment => 'Guardar Pago';

  @override
  String get promotionOrChangeLevel => 'Promover o Corregir Nivel';

  @override
  String get choseNewLevel => 'Selecciona el nuevo nivel';

  @override
  String get optional => 'opcional';

  @override
  String get studentSuccessPromotion => '¡Alumno promovido con éxito!';

  @override
  String promotionError(String e) {
    return 'Error al promover: $e';
  }

  @override
  String get changeRolMember => 'Cambiar Rol del Miembro';

  @override
  String get instructor => 'instructor';

  @override
  String get save => 'Guardar';

  @override
  String get updateRolSuccess => 'Rol actualizado con éxito.';

  @override
  String updateRolError(String e) {
    return 'Error al cambiar el rol: $e';
  }

  @override
  String get successPayment => 'Pago registrado con éxito.';

  @override
  String paymentError(String e) {
    return 'Error al registrar el pago: $e';
  }

  @override
  String get assignPlan => 'Asignar Plan de Pago';

  @override
  String get removeAssignedPlan => 'Quitar plan asignado';

  @override
  String get withPutLevel => 'Sin Nivel';

  @override
  String get registerPausedAssistance => 'Registrar Asistencia Pasada';

  @override
  String get errorLevelLoad => 'No se pudo cargar el nivel actual del alumno.';

  @override
  String get levelPromotion => 'Promover Nivel';

  @override
  String get assignTechnic => 'Asignar Técnicas';

  @override
  String get studentNotAssignedTechnics =>
      'Este alumno no tiene técnicas asignadas.';

  @override
  String get notassignedPaymentPlan => 'Sin plan de pago asignado.';

  @override
  String paymentPlanNotFoud(String assignedPlanId) {
    return 'Plan asignado (ID: $assignedPlanId) no encontrado.';
  }

  @override
  String get contactData => 'Datos de Contacto';

  @override
  String get saveAndContinue => 'Guardar y Continuar';
}
