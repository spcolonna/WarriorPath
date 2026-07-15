import {onSchedule} from "firebase-functions/v2/scheduler";
import {
  onDocumentCreated,
  onDocumentWritten,
} from "firebase-functions/v2/firestore";
import {onCall, HttpsError} from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";

admin.initializeApp();
const db = admin.firestore();

// ── Nivel de Poder: puntos otorgados por cada acción ─────────────────────────
// Mantener sincronizado con lib/config/power_config.dart (sólo UI).
const POINTS_PER_CLASS = 10;
const POINTS_PER_EVENT = 25;
const POINTS_PER_PROMOTION = 50;

/**
 * Suma poder a un conjunto de miembros de una escuela.
 * Usa set+merge para no abortar el batch si algún member no existiera.
 * @param {string} schoolId Id de la escuela.
 * @param {string[]} memberIds Ids de los miembros premiados.
 * @param {number} points Puntos a sumar a cada uno.
 * @param {FirebaseFirestore.WriteBatch} batch Batch donde encolar las sumas.
 */
function awardPower(
  schoolId: string,
  memberIds: string[],
  points: number,
  batch: FirebaseFirestore.WriteBatch,
) {
  for (const memberId of memberIds) {
    const memberRef = db.collection("schools").doc(schoolId)
      .collection("members").doc(memberId);
    batch.set(memberRef, {
      powerLevel: admin.firestore.FieldValue.increment(points),
    }, {merge: true});
  }
}

// ===============================================================================================
// FUNCIÓN 1: GENERAR RECORDATORIOS DE PAGO MENSUALES
// ===============================================================================================
// Corre TODOS los días 09:00 (Montevideo). Para cada escuela genera el
// recordatorio de pago sólo el día que coincide con su `financials.paymentDueDay`
// (ej. el 10). Antes corría el 1 e ignoraba el día configurado; además la query
// collectionGroup con `!=` moría por falta de índice compuesto (nunca generaba
// nada). Este rediseño usa queries de un solo campo (sin índice compuesto).
exports.generateMonthlyPaymentReminders = onSchedule(
  {
    schedule: "0 9 * * *",
    timeZone: "America/Montevideo",
  },
  async (_event) => {
    // Día del mes y período (YYYY-MM) en Montevideo — dentro de la función
    // `new Date()` es UTC, así que lo derivamos con Intl en la zona correcta.
    const tz = "America/Montevideo";
    const parts = new Intl.DateTimeFormat("en-CA", {
      timeZone: tz, year: "numeric", month: "2-digit", day: "2-digit",
    }).formatToParts(new Date());
    const get = (t: string) => parts.find((p) => p.type === t)?.value ?? "";
    const todayDay = parseInt(get("day"), 10);
    const periodKey = `${get("year")}-${get("month")}`; // ej. "2026-07"

    logger.info(
      `Recordatorios de pago: día ${todayDay}, período ${periodKey}.`);

    const schoolsSnap = await db.collection("schools").get();

    const perSchool = schoolsSnap.docs.map(async (schoolDoc) => {
      const schoolId = schoolDoc.id;
      const financials =
        (schoolDoc.data()?.financials ?? {}) as Record<string, unknown>;
      const dueDay = (financials.paymentDueDay as number | undefined) ?? 5;
      if (dueDay !== todayDay) return; // hoy no vence en esta escuela

      // Query de un solo campo → auto-indexada, sin índice compuesto.
      const membersSnap = await schoolDoc.ref.collection("members")
        .where("status", "==", "active").get();

      const perMember = membersSnap.docs.map(async (memberDoc) => {
        const memberData = memberDoc.data();
        const memberId = memberDoc.id;
        const planId = memberData.assignedPaymentPlanId as string | undefined;
        if (!planId) return;

        const remindersRef = schoolDoc.ref
          .collection("members").doc(memberId)
          .collection("paymentReminders");

        // Idempotencia por período: un recordatorio por mes por alumno.
        // (Antes se saltaba si había CUALQUIER pendiente, así que un impago
        //  viejo suprimía todos los meses siguientes.)
        const existing = await remindersRef
          .where("periodKey", "==", periodKey).limit(1).get();
        if (!existing.empty) return;

        const planDoc = await schoolDoc.ref
          .collection("paymentPlans").doc(planId).get();
        const planData = planDoc.data();
        if (!planDoc.exists || !planData) return;

        await remindersRef.add({
          concept: planData.title,
          amount: planData.amount,
          currency: planData.currency,
          status: "pending",
          planId: planId,
          studentId: memberId,
          schoolId: schoolId,
          periodKey: periodKey,
          createdOn: admin.firestore.FieldValue.serverTimestamp(),
        });

        await sendNotificationsToUser(memberId, {
          notification: {
            title: "Recordatorio de Pago",
            body: `Tu cuota de ${planData.title} vence hoy.`,
          },
        });
      });

      await Promise.all(perMember);
    });

    await Promise.all(perSchool);
    logger.info("Proceso de recordatorios completado.");
  });

// ===============================================================================================
// FUNCIÓN 2: NOTIFICAR SOBRE POSTULACIONES, ACEPTACIONES, PROMOCIONES Y TÉCNICAS
// ===============================================================================================
exports.onMemberStatusChange = onDocumentWritten(
  "/schools/{schoolId}/members/{memberId}",
  async (event) => {
    if (!event.data) return;
    const schoolId = event.params.schoolId;
    const memberId = event.params.memberId;
    const beforeData = event.data.before.data();
    const afterData = event.data.after.data();

    // Creación (Postulación)
    if (!event.data.before.exists && event.data.after.exists && afterData) {
      if (afterData.status === "pending") {
        try {
          const schoolDoc = await db.collection("schools").doc(schoolId).get();
          const ownerId = schoolDoc.data()?.ownerId;
          if (ownerId) {
            const payload = {
              notification: {
                title: "Nueva Solicitud de Ingreso",
                body: `${afterData.displayName} quiere unirse a tu escuela.`,
              },
            };
            await sendNotificationsToUser(ownerId, payload);
          }
        } catch (error) {
          logger.error("Error al notificar al dueño:", error);
        }
      }
    }

    // Actualización (Aceptación, Promoción, Técnicas)
    if (event.data.before.exists && event.data.after.exists && beforeData && afterData) {
      // Aceptación
      if (beforeData.status === "pending" && afterData.status === "active") {
        try {
          const schoolDoc = await db.collection("schools").doc(schoolId).get();
          const schoolName = schoolDoc.data()?.name ?? "tu escuela";
          const payload = {
            notification: {
              title: "¡Has sido Aceptado!",
              body: `Felicitaciones, tu solicitud para unirte a ${schoolName}` +
                                " ha sido aprobada.",
            },
          };
          await sendNotificationsToUser(memberId, payload);
        } catch (error) {
          logger.error("Error al notificar al alumno aceptado:", error);
        }
      }
      // Promoción
      if (beforeData.hasUnseenPromotion === false && afterData.hasUnseenPromotion === true) {
        try {
          const newLevelId = afterData.currentLevelId;
          let newLevelName = "un nuevo nivel";
          if (newLevelId) {
            const levelDoc = await db.collection("schools").doc(schoolId)
              .collection("levels").doc(newLevelId).get();
            newLevelName = levelDoc.data()?.name ?? newLevelName;
          }
          const payload = {
            notification: {
              title: "¡Felicitaciones, has sido promovido!",
              body: `Has alcanzado el nivel de ${newLevelName}. ¡Sigue así!`,
            },
          };
          await sendNotificationsToUser(memberId, payload);
        } catch (error) {
          logger.error("Error al notificar sobre promoción:", error);
        }
      }
      // Técnicas
      const beforeTechs = new Set(beforeData.assignedTechniqueIds ?? []);
      const afterTechs = afterData.assignedTechniqueIds ?? [];
      const newTechIds = afterTechs.filter((id: string) => !beforeTechs.has(id));
      if (newTechIds.length > 0) {
        try {
          const payload = {
            notification: {
              title: "Nuevas Técnicas Asignadas",
              body: `Tu maestro te ha asignado ${newTechIds.length} nueva(s)` +
                                " técnica(s). ¡Revísalas en tu progreso!",
            },
          };
          await sendNotificationsToUser(memberId, payload);
        } catch (error) {
          logger.error("Error al notificar sobre nuevas técnicas:", error);
        }
      }
    }
  });

// ===============================================================================================
// FUNCIÓN 3: NOTIFICAR SOBRE NUEVO PAGO REGISTRADO
// ===============================================================================================
exports.onPaymentCreated = onDocumentWritten(
  "/schools/{schoolId}/members/{studentId}/payments/{paymentId}",
  async (event) => {
    if (!event.data?.after.exists || event.data.before.exists) return;
    const paymentData = event.data.after.data();
    const studentId = event.params.studentId;
    if (!paymentData) return;
    const amount = paymentData.amount ?? 0;
    const currency = paymentData.currency ?? "";
    const concept = paymentData.concept ?? "un pago";
    const payload = {
      notification: {
        title: "Nuevo Pago Registrado",
        body: `Tu maestro ha registrado un pago de ${amount} ${currency}` +
                    ` por concepto de "${concept}".`,
      },
    };
    try {
      await sendNotificationsToUser(studentId, payload);
    } catch (error) {
      logger.error("Error al notificar sobre nuevo pago:", error);
    }
  });

// ===============================================================================================
// FUNCIÓN 4: NOTIFICAR SOBRE NUEVA ASISTENCIA REGISTRADA
// ===============================================================================================
exports.onAttendanceUpdated = onDocumentWritten(
  "/schools/{schoolId}/attendanceRecords/{recordId}",
  async (event) => {
    // Sólo ignoramos borrados. Las CREACIONES sí se procesan: el auto
    // check-in del alumno crea el registro con su id ya incluido en
    // presentStudentIds (school_info_tab_screen), y antes ese camino no
    // otorgaba poder ni notificaba.
    if (!event.data?.after.exists) return;
    const afterData = event.data.after.data();
    if (!afterData) return;

    const beforeData = event.data.before.exists ?
      event.data.before.data() : undefined;
    const beforeStudentIds = new Set(beforeData?.presentStudentIds ?? []);
    const afterStudentIds = afterData.presentStudentIds ?? [];
    const newStudentIds: string[] = afterStudentIds
      .filter((id: string) => !beforeStudentIds.has(id));
    if (newStudentIds.length === 0) return;

    logger.info(
      `Asistencia ${event.params.recordId} (${afterData.scheduleTitle}): ` +
      `nuevos presentes [${newStudentIds.join(", ")}]`);

    // ── Nivel de Poder: sumar puntos a los recién-presentes ──────────────────
    // Idempotente: sólo se otorga a ids que todavía no están en
    // `awardedPowerStudentIds`, y se los agrega al array en la misma escritura.
    // Así desmarcar/re-marcar NO vuelve a sumar. El re-trigger que provoca este
    // update no re-otorga (presentStudentIds no cambia → newStudentIds vacío).
    const schoolId = event.params.schoolId;
    const alreadyAwarded =
      new Set<string>(afterData.awardedPowerStudentIds ?? []);
    const toAward = newStudentIds.filter((id) => !alreadyAwarded.has(id));
    if (toAward.length > 0) {
      const batch = db.batch();
      awardPower(schoolId, toAward, POINTS_PER_CLASS, batch);
      batch.set(event.data.after.ref, {
        awardedPowerStudentIds:
          admin.firestore.FieldValue.arrayUnion(...toAward),
      }, {merge: true});
      try {
        await batch.commit();
        logger.info(
          `Poder otorgado (+${POINTS_PER_CLASS}) a: ${toAward.join(", ")}`);
      } catch (error) {
        logger.error("Error otorgando poder por asistencia:", error);
      }
    }

    const scheduleTitle = afterData.scheduleTitle ?? "una clase";
    const payload = {
      notification: {
        title: "Asistencia Registrada",
        body: "¡Presente! Se ha registrado tu asistencia para la clase de" +
                    ` "${scheduleTitle}".`,
      },
    };
    const notificationPromises = newStudentIds
      .map((studentId) => sendNotificationsToUser(studentId, payload));
    try {
      await Promise.all(notificationPromises);
    } catch (error) {
      logger.error("Error enviando notificaciones de asistencia:", error);
    }
  });

// ===============================================================================================
// FUNCIÓN 4B: PREMIAR PROMOCIONES DE NIVEL CON PODER
// ===============================================================================================
// El maestro promueve creando un doc en progressionHistory (progress_discipline_tab).
// onDocumentCreated dispara una sola vez por doc, así que es naturalmente idempotente.
exports.onPromotionCreated = onDocumentCreated(
  "/schools/{schoolId}/members/{memberId}/progressionHistory/{promoId}",
  async (event) => {
    const data = event.data?.data();
    if (!data || data.type !== "level_promotion") return;

    const {schoolId, memberId} = event.params;
    const batch = db.batch();
    awardPower(schoolId, [memberId], POINTS_PER_PROMOTION, batch);
    try {
      await batch.commit();
      logger.info(
        `Promoción de ${memberId}: poder +${POINTS_PER_PROMOTION}`);
    } catch (error) {
      logger.error("Error otorgando poder por promoción:", error);
    }
  });

// ===============================================================================================
// FUNCIÓN 5: EVENTOS — NOTIFICAR INVITACIONES Y PREMIAR CONFIRMACIONES
// ===============================================================================================
exports.onEventAssigned = onDocumentWritten(
  "/schools/{schoolId}/events/{eventId}",
  async (event) => {
    if (!event.data?.before.exists || !event.data?.after.exists) return;
    const beforeData = event.data.before.data();
    const afterData = event.data.after.data();
    if (!beforeData || !afterData) return;

    // ── Nivel de Poder: premiar a quienes recién confirman asistencia ────────
    // El alumno escribe attendeeStatus.{uid} = 'confirmado' al aceptar.
    // Idempotente vía powerAwardedIds en el propio evento: confirmar →
    // rechazar → confirmar no vuelve a sumar.
    const beforeStatus: Record<string, string> =
      beforeData.attendeeStatus ?? {};
    const afterStatus: Record<string, string> = afterData.attendeeStatus ?? {};
    const alreadyAwarded =
      new Set<string>(afterData.powerAwardedIds ?? []);
    const newlyConfirmed = Object.keys(afterStatus).filter((uid) =>
      afterStatus[uid] === "confirmado" &&
      beforeStatus[uid] !== "confirmado" &&
      !alreadyAwarded.has(uid));

    if (newlyConfirmed.length > 0) {
      const batch = db.batch();
      awardPower(
        event.params.schoolId, newlyConfirmed, POINTS_PER_EVENT, batch);
      batch.set(event.data.after.ref, {
        powerAwardedIds:
          admin.firestore.FieldValue.arrayUnion(...newlyConfirmed),
      }, {merge: true});
      try {
        await batch.commit();
        logger.info(
          `Evento ${event.params.eventId}: poder (+${POINTS_PER_EVENT}) ` +
          `a confirmados [${newlyConfirmed.join(", ")}]`);
      } catch (error) {
        logger.error("Error otorgando poder por evento:", error);
      }
    }

    // ── Notificaciones de invitación (comportamiento original) ───────────────
    const beforeInvitedIds = new Set(beforeData.invitedStudentIds ?? []);
    const afterInvitedIds = afterData.invitedStudentIds ?? [];
    const newStudentIds: string[] = afterInvitedIds
      .filter((id: string) => !beforeInvitedIds.has(id));
    if (newStudentIds.length === 0) return;

    const eventName = afterData.name ?? "un nuevo evento";
    const payload = {
      notification: {
        title: "Invitación a un Evento",
        body: `Has sido invitado al evento: "${eventName}".` +
                    " ¡Revisa la app para más detalles!",
      },
    };
    const notificationPromises = newStudentIds
      .map((studentId) => sendNotificationsToUser(studentId, payload));
    try {
      await Promise.all(notificationPromises);
    } catch (error) {
      logger.error("Error enviando notificaciones de evento:", error);
    }
  });

// ===============================================================================================
// FUNCIÓN 6: VINCULAR ALUMNO SIN APP (OFFLINE) CON UNA CUENTA REAL
// ===============================================================================================
// Transfiere toda la info de un alumno proxy (sin cuenta) a la cuenta real de un
// alumno ya inscripto: progreso, pagos, historial de progresión, recordatorios,
// asistencias y eventos. El alumno offline queda deshabilitado (status 'merged').
exports.linkOfflineStudent = onCall(async (request) => {
  const callerUid = request.auth?.uid;
  if (!callerUid) {
    throw new HttpsError("unauthenticated", "Debés iniciar sesión.");
  }

  const {schoolId, offlineMemberId, targetMemberId} = request.data ?? {};
  if (!schoolId || !offlineMemberId || !targetMemberId) {
    throw new HttpsError(
      "invalid-argument",
      "Faltan parámetros: schoolId, offlineMemberId, targetMemberId.");
  }
  if (offlineMemberId === targetMemberId) {
    throw new HttpsError(
      "invalid-argument", "No se puede vincular un alumno consigo mismo.");
  }

  const schoolRef = db.collection("schools").doc(schoolId);
  const schoolSnap = await schoolRef.get();
  if (!schoolSnap.exists) {
    throw new HttpsError("not-found", "La escuela no existe.");
  }
  // Solo el dueño de la escuela puede vincular cuentas.
  if (schoolSnap.data()?.ownerId !== callerUid) {
    throw new HttpsError(
      "permission-denied", "Solo el dueño de la escuela puede vincular cuentas.");
  }

  const offlineMemberRef = schoolRef.collection("members").doc(offlineMemberId);
  const targetMemberRef = schoolRef.collection("members").doc(targetMemberId);

  const [offlineSnap, targetSnap] = await Promise.all([
    offlineMemberRef.get(), targetMemberRef.get(),
  ]);
  if (!offlineSnap.exists) {
    throw new HttpsError("not-found", "El alumno sin app no existe.");
  }
  if (!targetSnap.exists) {
    throw new HttpsError("not-found", "El alumno destino no existe.");
  }

  const offlineData = offlineSnap.data() ?? {};
  const targetData = targetSnap.data() ?? {};

  // 1) Merge de progreso: ante conflicto de disciplina, gana la del alumno
  //    offline porque tiene el historial real de grado acumulado.
  const targetProgress = (targetData.progress ?? {}) as Record<string, unknown>;
  const offlineProgress =
    (offlineData.progress ?? {}) as Record<string, unknown>;
  const mergedProgress = {...targetProgress, ...offlineProgress};

  // Buffer de operaciones; se vuelca en lotes de a 450 para no superar el
  // límite de 500 writes por batch de Firestore.
  const ops: Array<() => void> = [];
  let batch = db.batch();
  let count = 0;
  const flushIfNeeded = async () => {
    if (count >= 450) {
      await batch.commit();
      batch = db.batch();
      count = 0;
    }
  };
  const queue = (fn: (b: FirebaseFirestore.WriteBatch) => void) => {
    ops.push(() => fn(batch));
  };

  // 2) Copiar subcolecciones del miembro offline al miembro real.
  const subcollections = ["payments", "progressionHistory", "paymentReminders"];
  for (const sub of subcollections) {
    const snap = await offlineMemberRef.collection(sub).get();
    for (const doc of snap.docs) {
      queue((b) => b.set(targetMemberRef.collection(sub).doc(doc.id), doc.data()));
    }
  }

  // Reemplaza offlineMemberId por targetMemberId en un array, sin duplicar.
  const swapId = (arr: unknown): string[] => {
    const ids = (Array.isArray(arr) ? arr : []) as string[];
    const next = ids.filter((id) => id !== offlineMemberId);
    if (!next.includes(targetMemberId)) next.push(targetMemberId);
    return next;
  };

  // 3) Asistencias: reemplazar el id offline por el real en presentStudentIds.
  const attendanceSnap = await schoolRef.collection("attendanceRecords")
    .where("presentStudentIds", "array-contains", offlineMemberId).get();
  for (const doc of attendanceSnap.docs) {
    const next = swapId(doc.data().presentStudentIds);
    queue((b) => b.update(doc.ref, {presentStudentIds: next}));
  }

  // 4) Eventos: mismo swap en invitedStudentIds.
  const eventsSnap = await schoolRef.collection("events")
    .where("invitedStudentIds", "array-contains", offlineMemberId).get();
  for (const doc of eventsSnap.docs) {
    const next = swapId(doc.data().invitedStudentIds);
    queue((b) => b.update(doc.ref, {invitedStudentIds: next}));
  }

  // 5) Actualizar el miembro real: progreso fusionado + datos que no tenga.
  const targetUpdate: Record<string, unknown> = {progress: mergedProgress};
  if (!targetData.assignedPaymentPlanId && offlineData.assignedPaymentPlanId) {
    targetUpdate.assignedPaymentPlanId = offlineData.assignedPaymentPlanId;
  }
  if (offlineData.achievements) {
    targetUpdate.achievements = {
      ...(offlineData.achievements as Record<string, unknown>),
      ...((targetData.achievements ?? {}) as Record<string, unknown>),
    };
  }
  queue((b) => b.update(targetMemberRef, targetUpdate));

  // 6) Deshabilitar el alumno offline (member + perfil proxy en users).
  queue((b) => b.update(offlineMemberRef, {
    status: "merged",
    mergedInto: targetMemberId,
    mergedAt: admin.firestore.FieldValue.serverTimestamp(),
  }));
  queue((b) => b.update(db.collection("users").doc(offlineMemberId), {
    isDisabled: true,
    mergedInto: targetMemberId,
    mergedAt: admin.firestore.FieldValue.serverTimestamp(),
  }));

  // Ejecutar todas las operaciones en lotes.
  for (const op of ops) {
    op();
    count++;
    await flushIfNeeded();
  }
  if (count > 0) await batch.commit();

  logger.info(
    `Vinculado offline ${offlineMemberId} -> ${targetMemberId} ` +
    `en escuela ${schoolId} por ${callerUid}.`);

  return {success: true, targetMemberId};
});

// ===============================================================================================
// FUNCIÓN 7: ELIMINAR LA PROPIA CUENTA (App Store Guideline 5.1.1(v))
// ===============================================================================================
// Borra la cuenta del usuario que la invoca: su documento en users, sus
// membresías en cada escuela, sus perfiles de hijos (proxy) y guardianías, y
// por último la cuenta de Firebase Auth vía Admin SDK (no requiere login
// reciente, evitando el error requires-recent-login del lado del cliente).
exports.deleteMyAccount = onCall(async (request) => {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "Debés iniciar sesión.");
  }

  const userRef = db.collection("users").doc(uid);
  const userSnap = await userRef.get();
  const userData = userSnap.data() ?? {};

  const batch = db.batch();

  // Quitar las membresías del usuario en cada escuela.
  const memberships =
    (userData.activeMemberships ?? {}) as Record<string, unknown>;
  for (const schoolId of Object.keys(memberships)) {
    batch.delete(
      db.collection("schools").doc(schoolId).collection("members").doc(uid));
  }

  // Eliminar guardianías de este usuario y los perfiles proxy de sus hijos.
  const guardianshipsSnap = await db.collection("guardianships")
    .where("guardianId", "==", uid).get();
  for (const g of guardianshipsSnap.docs) {
    const childId = g.data().childId as string | undefined;
    if (childId) {
      const childSnap = await db.collection("users").doc(childId).get();
      const childMemberships =
        (childSnap.data()?.activeMemberships ?? {}) as Record<string, unknown>;
      for (const schoolId of Object.keys(childMemberships)) {
        batch.delete(db.collection("schools").doc(schoolId)
          .collection("members").doc(childId));
      }
      batch.delete(db.collection("users").doc(childId));
    }
    batch.delete(g.ref);
  }

  // Eliminar el documento del propio usuario.
  batch.delete(userRef);

  await batch.commit();

  // Borrar la cuenta de autenticación (Admin SDK, sin login reciente).
  await admin.auth().deleteUser(uid);

  logger.info(`Cuenta eliminada: ${uid}`);
  return {success: true};
});

// ===============================================================================================
// FUNCIÓN 8: ABANDONAR LA CREACIÓN DE ESCUELA (descartar wizard a medio hacer)
// ===============================================================================================
// Borra recursivamente la escuela a medio crear y sus subcolecciones, quita la
// membresía del usuario y recalcula su `wizardStep` para que no quede atrapado
// en el wizard (post_auth_navigator fuerza el wizard mientras wizardStep < 99).
// Devuelve el wizardStep resultante para que el cliente rutee.
exports.abandonSchoolSetup = onCall(async (request) => {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "Debés iniciar sesión.");
  }

  const {schoolId} = request.data ?? {};
  const userRef = db.collection("users").doc(uid);

  if (schoolId) {
    const schoolRef = db.collection("schools").doc(schoolId);
    const schoolSnap = await schoolRef.get();
    // Sólo el dueño puede descartar su escuela a medio crear.
    if (schoolSnap.exists && schoolSnap.data()?.ownerId !== uid) {
      throw new HttpsError(
        "permission-denied", "Sólo el dueño puede descartar esta escuela.");
    }
    if (schoolSnap.exists) {
      // Borrado recursivo: la escuela + todas sus subcolecciones
      // (disciplines/levels/techniques, members, paymentPlans, etc.).
      await db.recursiveDelete(schoolRef);
    }
  }

  // Quitar la membresía de esta escuela y recalcular wizardStep.
  const userSnap = await userRef.get();
  const memberships =
    {...((userSnap.data()?.activeMemberships ?? {}) as Record<string, unknown>)};
  if (schoolId) delete memberships[schoolId];

  // Si quedan otras membresías, el usuario ya está onboardeado (99). Si no,
  // vuelve al inicio del wizard para re-elegir rol (0).
  const wizardStep = Object.keys(memberships).length > 0 ? 99 : 0;

  const update: Record<string, unknown> = {wizardStep};
  if (schoolId) {
    update[`activeMemberships.${schoolId}`] =
      admin.firestore.FieldValue.delete();
  }
  await userRef.set(update, {merge: true});

  logger.info(`Escuela abandonada por ${uid}: ${schoolId ?? "(sin schoolId)"}` +
    ` → wizardStep=${wizardStep}`);
  return {wizardStep};
});

// ===============================================================================================
// FUNCIÓN AUXILIAR: ENVIAR NOTIFICACIONES A UN USUARIO
// ===============================================================================================
/**
 * Envía notificaciones a los tokens de un usuario.
 * @param {string} userId El ID del usuario.
 * @param {object} payload El contenido de la notificación.
 */
async function sendNotificationsToUser(
  userId: string,
  payload: {notification: {title: string, body: string}}
) {
  try {
    const userDoc = await db.collection("users").doc(userId).get();
    if (!userDoc.exists) {
      logger.warn(`Usuario ${userId} no encontrado, no se puede notificar.`);
      return;
    }
    const tokens = userDoc.data()?.fcmTokens as string[] | undefined;
    if (tokens && tokens.length > 0) {
      const message = {
        tokens: tokens,
        ...payload,
      };
      const response = await admin.messaging().sendEachForMulticast(message);
      const tokensToRemove: Promise<FirebaseFirestore.WriteResult>[] = [];
      response.responses.forEach(
        (result: admin.messaging.SendResponse, index: number) => {
          if (!result.success) {
            const error = result.error;
            if (error) {
              const errorCode = error.code;
              if (errorCode === "messaging/invalid-registration-token" ||
                                errorCode === "messaging/registration-token-not-registered") {
                tokensToRemove.push(db.collection("users").doc(userId).update({
                  fcmTokens: admin.firestore.FieldValue.arrayRemove(tokens[index]),
                }));
              }
            }
          }
        });
      await Promise.all(tokensToRemove);
    }
  } catch (error) {
    logger.error(`Error enviando notificaciones a ${userId}:`, error);
  }
}
