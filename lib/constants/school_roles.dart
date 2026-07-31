/// Roles de un miembro DENTRO de una escuela.
///
/// Ojo: son distintos de `users/{uid}.role` (nivel cuenta: student/teacher/
/// parent/both). Estos son los que se guardan en `schools/{id}/members/{uid}.role`
/// y en `users/{uid}.activeMemberships[schoolId]`.
///
/// Antes estos valores se tomaban de l10n, con lo que un teléfono en inglés
/// guardaba 'teacher' en vez de 'maestro' y dejaba de matchear con el resto de
/// la app. Los valores persistidos SIEMPRE salen de acá; l10n es sólo para mostrar.
class SchoolRoles {
  SchoolRoles._();

  static const String maestro = 'maestro';
  static const String instructor = 'instructor';
  static const String alumno = 'alumno';

  static const List<String> all = [maestro, instructor, alumno];
}

/// Estados de una membresía (`schools/{id}/members/{uid}.status`).
class MemberStatus {
  MemberStatus._();

  /// Se postuló y espera aprobación del maestro.
  static const String pending = 'pending';

  /// Miembro activo de la escuela.
  static const String active = 'active';

  /// Dado de baja por un maestro. Conserva todo su historial: si se lo
  /// reactiva, recupera progreso y cinturón intactos. No puede volver a
  /// postularse por su cuenta — sólo un maestro puede reactivarlo.
  static const String inactive = 'inactive';
}
