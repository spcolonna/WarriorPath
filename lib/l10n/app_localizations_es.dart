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

  @override
  String get subscriptionExpired => 'Suscripción Vencida';

  @override
  String get subscriptionExpiredMessage =>
      'Tu acceso a las herramientas de maestro ha sido pausado. Para renovar tu suscripción y reactivar tu cuenta, por favor, contacta al administrador.';

  @override
  String get contactAdmin => 'Contactar al Administrador';

  @override
  String get renewalSubject => 'Renovación de Suscripción - Warrior Path';

  @override
  String get mailError => 'No se pudo abrir la aplicación de correo.';

  @override
  String mailLaunchError(String e) {
    return 'Error al intentar abrir el correo: $e';
  }

  @override
  String get nameAndMartialArtRequired =>
      'Nombre y Arte Marcial son requeridos.';

  @override
  String get needSelectSubSchool =>
      'Si es una sub-escuela, debes seleccionar la escuela principal.';

  @override
  String get notAuthenticatedUser => 'Usuario no autenticado.';

  @override
  String createSchoolError(String e) {
    return 'Error al crear la escuela: $e';
  }

  @override
  String get crateSchoolStep2 => 'Crear tu Escuela (Paso 2)';

  @override
  String get isSubSchool => '¿Es una Sub-Escuela?';

  @override
  String get pickAColor => 'Elige un color';

  @override
  String get select => 'Seleccionar';

  @override
  String get configureLevelsStep3 => 'Configurar Niveles (Paso 3)';

  @override
  String get addYourFirstLevel => 'Añade tu primer nivel abajo.';

  @override
  String get addLevel => 'Añadir Nivel';

  @override
  String get schoolManagement => 'Gestión de la Escuela';

  @override
  String get noActiveSchoolError =>
      'Error: No hay una escuela activa en la sesión.';

  @override
  String get myProfileAndActions => 'Mi Perfil y Acciones';

  @override
  String get logOut => 'Cerrar Sesión';

  @override
  String get editMyProfile => 'Editar mi Perfil';

  @override
  String get updateProfileInfo => 'Actualiza tu nombre, foto o contraseña.';

  @override
  String get switchProfileSchool => 'Cambiar de Perfil/Escuela';

  @override
  String get accessOtherRoles => 'Accede a tus otros roles o escuelas.';

  @override
  String get enrollInAnotherSchool => 'Inscribirme en otra Escuela';

  @override
  String get joinAnotherCommunity => 'Únete a otra comunidad como alumno.';

  @override
  String get createNewSchool => 'Crear una Nueva Escuela';

  @override
  String get expandYourLegacy => 'Expande tu legado o abre una nueva sucursal.';

  @override
  String get students => 'Alumnos';

  @override
  String get reject => 'Rechazar';

  @override
  String get accept => 'Aceptar';

  @override
  String get selectProfile => 'Seleccionar Perfil';

  @override
  String get addSchedule => 'Añadir Horario';

  @override
  String get saveSchedule => 'Guardar Horario';

  @override
  String get confirmDeletion => 'Confirmar Eliminación';

  @override
  String get confirmDeleteSchedule =>
      '¿Estás seguro de que quieres eliminar este horario?';

  @override
  String get manageSchedules => 'Gestionar Horarios';

  @override
  String get confirmDeleteEvent =>
      '¿Estás seguro de que quieres eliminar este evento permanentemente? Esta acción no se puede deshacer.';

  @override
  String get eventDeleted => 'Evento eliminado.';

  @override
  String get eventNoLongerExists => 'Este evento ya no existe.';

  @override
  String get attendees => 'Asistentes';

  @override
  String get manageGuests => 'Gestionar Invitados';

  @override
  String get noStudentsInvitedYet => 'Aún no has invitado a ningún alumno.';

  @override
  String get endTime => 'Hora de Fin';

  @override
  String get startTime => 'Hora de Inicio';

  @override
  String get daysOfTheWeek => 'Días de la semana';

  @override
  String get classTitle => 'Título de la Clase';

  @override
  String get classTitleExample => 'Ej: Niños, Adultos, Kicks';

  @override
  String get scheduleSavedSuccess => 'Horario guardado con éxito.';

  @override
  String get endTimeAfterStartTimeError =>
      'La hora de fin debe ser posterior a la hora de inicio.';

  @override
  String get pleaseFillAllFields =>
      'Por favor, completa todos los campos requeridos.';

  @override
  String get unknownSchool => 'Escuela Desconocida';

  @override
  String get noActiveProfilesFound => 'No se encontraron perfiles activos.';

  @override
  String enterAs(String e) {
    return 'Entrar como $e';
  }

  @override
  String inSchool(String message) {
    return 'en $message';
  }

  @override
  String yourAnswer(String message) {
    return 'Tu Respuesta: $message';
  }

  @override
  String get cost => 'Costo';

  @override
  String get time => 'Hora';

  @override
  String get date => 'Fecha';

  @override
  String get location => 'Ubicación';

  @override
  String get invited => 'Invitado';

  @override
  String get eventDetails => 'Detalles del Evento';

  @override
  String errorSendingResponse(String e) {
    return 'Error al enviar respuesta: $e';
  }

  @override
  String responseSent(String message) {
    return 'Respuesta enviada: $message';
  }

  @override
  String get manageEvents => 'Gestionar Eventos';

  @override
  String get manageEventsDescription => 'Crea exámenes, torneos y seminarios.';

  @override
  String get manageSchedulesDescription =>
      'Define los turnos y días de tus clases.';

  @override
  String get manageLevels => 'Gestionar Niveles';

  @override
  String get manageLevelsDescription =>
      'Edita los nombres, colores y orden de las fajas/cinturones.';

  @override
  String get manageTechniques => 'Gestionar Técnicas';

  @override
  String get manageTechniquesDescription =>
      'Añade o modifica el currículo de tu escuela.';

  @override
  String get manageFinances => 'Gestionar Finanzas';

  @override
  String get manageFinancesDescription =>
      'Ajusta los precios y planes de pago.';

  @override
  String get editSchoolData => 'Editar Datos de la Escuela';

  @override
  String get editSchoolDataDescription =>
      'Modifica la dirección, teléfono, descripción, etc.';

  @override
  String get upcoming => 'Próximos';

  @override
  String get past => 'Pasados';

  @override
  String get noUpcomingEvents => 'No hay eventos próximos.';

  @override
  String get noPastEvents => 'No hay eventos pasados.';

  @override
  String get errorNoActiveSession => 'Error: No hay una sesión activa.';

  @override
  String get profileLoadedError => 'No se pudo cargar el perfil.';

  @override
  String get fullName => 'Nombre y Apellido';

  @override
  String get saveChanges => 'Guardar Cambios';

  @override
  String get emergencyInfoNotice =>
      'Esta información solo será visible para los maestros de tu escuela en caso de ser necesario.';

  @override
  String get emergencyContactName => 'Nombre del Contacto de Emergencia';

  @override
  String get emergencyContactPhone => 'Teléfono del Contacto de Emergencia';

  @override
  String get medicalEmergencyService => 'Servicio de Emergencia Médica';

  @override
  String get medicalServiceExample => 'Ej: SEMM, Emergencia Uno, UCM';

  @override
  String get relevantMedicalInfo => 'Información Médica Relevante';

  @override
  String get medicalInfoExample => 'Ej: Alergias, asma, medicación, etc.';

  @override
  String get accountActions => 'Acciones de Cuenta';

  @override
  String get becomeATeacher => 'Conviértete en maestro e inicia tu camino.';

  @override
  String get myData => 'Mis Datos';

  @override
  String get myProfile => 'Mi Perfil';

  @override
  String profileUpdateError(String message) {
    return 'Error al actualizar el perfil: $message';
  }

  @override
  String noStudentsWithStatus(String state) {
    return 'No hay alumnos en estado $state';
  }

  @override
  String get noName => 'Sin Nombre';

  @override
  String applicationDate(String message) {
    return 'Fecha de solicitud: $message';
  }

  @override
  String get noLevelsConfiguredError =>
      'Tu escuela no tiene niveles configurados. Ve a Gestión -> Niveles para añadirlos.';

  @override
  String get studentAcceptedSuccess => 'Alumno aceptado con éxito.';

  @override
  String get applicationRejected => 'Solicitud rechazada.';

  @override
  String get monday => 'Lunes';

  @override
  String get tuesday => 'Martes';

  @override
  String get wednesday => 'Miércoles';

  @override
  String get thursday => 'Jueves';

  @override
  String get friday => 'Viernes';

  @override
  String get saturday => 'Sábado';

  @override
  String get sunday => 'Domingo';

  @override
  String get noSchedulesDefined =>
      'No hay horarios definidos.\nPresiona (+) para añadir el primero.';

  @override
  String get schoolCommunity => 'Comunidad de la Escuela';

  @override
  String get errorLoadingLevels => 'Error al cargar los niveles de la escuela.';

  @override
  String get errorLoadingMembers => 'Error al cargar los miembros.';

  @override
  String get noActiveMembersYet => 'Aún no hay miembros activos en la escuela.';

  @override
  String get instructors => 'Instructores';

  @override
  String get myPayments => 'Mis Pagos';

  @override
  String get errorLoadingPaymentHistory =>
      'Error al cargar tu historial de pagos.';

  @override
  String get noPaymentsRegisteredYet => 'Aún no tienes pagos registrados.';

  @override
  String paymentDetails(String concept, String date) {
    return '$concept\nPagado el $date';
  }

  @override
  String get myProgress => 'Mi Progreso';

  @override
  String get couldNotLoadProgress => 'No se pudo cargar tu progreso.';

  @override
  String get yourPath => 'Tu Camino';

  @override
  String get promotionHistory => 'Historial de Promociones';

  @override
  String get assignedTechniques => 'Técnicas Asignadas';

  @override
  String get myAttendanceHistory => 'Mi Historial de Asistencia';

  @override
  String get noLevelAssignedYet => 'Aún no tienes un nivel asignado.';

  @override
  String get yourCurrentLevel => 'Tu Nivel Actual';

  @override
  String get progressionSystemNotDefined =>
      'El sistema de progresión no ha sido definido.';

  @override
  String get teacherHasNotAssignedTechniques =>
      'Tu maestro aún no te ha asignado técnicas.';

  @override
  String get noPromotionsRegisteredYet =>
      'Aún no tienes promociones registradas.';

  @override
  String couldNotOpenVideo(String link) {
    return 'No se pudo abrir el video: $link';
  }

  @override
  String get noDescriptionAvailable => 'No hay descripción disponible.';

  @override
  String get watchTechniqueVideo => 'Ver Video de la Técnica';

  @override
  String get close => 'Cerrar';

  @override
  String get mySchool => 'Mi Escuela';

  @override
  String get couldNotLoadSchoolInfo =>
      'No se pudo cargar la información de la escuela.';

  @override
  String get schoolName => 'Nombre de la Escuela';

  @override
  String get martialArt => 'Arte Marcial';

  @override
  String get address => 'Dirección';

  @override
  String get upcomingEvents => 'Próximos Eventos';

  @override
  String get classSchedule => 'Horario de Clases';

  @override
  String get scheduleNotDefinedYet => 'El horario aún no ha sido definido.';

  @override
  String get updateProfileSuccess => 'Perfil actualizado con éxito.';

  @override
  String get manageChildren => 'Gestionar Hijos';

  @override
  String get manageChildrenSubtitle =>
      'Añade a tus hijos y gestiona sus perfiles.';
}
