import '../constants/school_roles.dart';

/// Quién puede hacer qué dentro de una escuela.
///
/// Antes el único predicado de permisos era `uid == ownerId`, duplicado como
/// `_isOwnerViewing` en varias pantallas. Eso hacía que promover a alguien a
/// "maestro" no le diera ningún privilegio real.
///
/// Ahora hay dos niveles:
///  - [canManageSchool]: gestión del día a día. Owner y maestros.
///  - [isOwner]: acciones destructivas o de traspaso de poder. Sólo el dueño.
class SchoolPermissions {
  SchoolPermissions._();

  /// Gestión operativa: asistencia, pagos, progreso, técnicas, alumnos,
  /// eventos, currícula. La comparten el dueño y cualquier maestro.
  static bool canManageSchool({
    required String? uid,
    required String? ownerId,
    required String? memberRole,
  }) {
    if (uid == null) return false;
    return uid == ownerId || memberRole == SchoolRoles.maestro;
  }

  /// Acciones irreversibles o que cambian quién manda: borrar la escuela,
  /// promover/degradar maestros, descartar el setup.
  ///
  /// Se mantienen exclusivas del dueño a propósito, para que un co-maestro no
  /// pueda borrar la escuela ni quitarle el control al dueño.
  static bool isOwner({required String? uid, required String? ownerId}) {
    return uid != null && uid == ownerId;
  }
}
