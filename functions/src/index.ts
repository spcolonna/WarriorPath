import {onSchedule} from "firebase-functions/v2/scheduler";
import {onDocumentWritten} from "firebase-functions/v2/firestore";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";

admin.initializeApp();
const db = admin.firestore();

// ===============================================================================================
// FUNCIÓN 1: GENERAR RECORDATORIOS DE PAGO MENSUALES
// ===============================================================================================
exports.generateMonthlyPaymentReminders = onSchedule(
  {
    schedule: "0 9 1 * *",
    timeZone: "America/Montevideo",
  },
  async (_event) => { // Corregido: 'event' a '_event' para 'unused-vars'
    logger.info("Iniciando la generación de recordatorios de pago mensuales...");

    const membersQuery = db.collectionGroup("members")
      .where("status", "==", "active")
      .where("assignedPaymentPlanId", "!=", null);

    const activeMembersSnap = await membersQuery.get();
    if (activeMembersSnap.empty) {
      logger.info("No se encontraron miembros con planes asignados.");
      return;
    }

    const promises: Promise<void>[] = [];
    activeMembersSnap.docs.forEach((memberDoc) => {
      const memberData = memberDoc.data();
      const memberId = memberDoc.id;
      const schoolId = memberDoc.ref.parent.parent?.id;
      if (!schoolId) return;

      const planId = memberData.assignedPaymentPlanId;
      const processingPromise = async () => {
        const pendingRemindersSnap = await db.collection("schools").doc(schoolId)
          .collection("members").doc(memberId)
          .collection("paymentReminders")
          .where("status", "==", "pending")
          .limit(1).get();

        if (pendingRemindersSnap.empty) {
          const planDoc = await db.collection("schools").doc(schoolId)
            .collection("paymentPlans").doc(planId).get();
          const planData = planDoc.data();
          if (!planDoc.exists || !planData) return;

          const reminderData = {
            concept: planData.title,
            amount: planData.amount,
            currency: planData.currency,
            status: "pending",
            planId: planId,
            studentId: memberId,
            schoolId: schoolId,
            createdOn: admin.firestore.FieldValue.serverTimestamp(),
          };
          await db.collection("schools").doc(schoolId)
            .collection("members").doc(memberId)
            .collection("paymentReminders").add(reminderData);

          const payload = {
            notification: {
              title: "Recordatorio de Pago",
              body: `Tu pago de ${planData.title} está listo.`,
            },
          };
          await sendNotificationsToUser(memberId, payload);
        }
      };
      promises.push(processingPromise());
    });
    await Promise.all(promises);
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
    if (!event.data?.before.exists || !event.data?.after.exists) return;
    const beforeData = event.data.before.data();
    const afterData = event.data.after.data();
    if (!beforeData || !afterData) return;

    const beforeStudentIds = new Set(beforeData.presentStudentIds ?? []);
    const afterStudentIds = afterData.presentStudentIds ?? [];
    const newStudentIds: string[] = afterStudentIds
      .filter((id: string) => !beforeStudentIds.has(id));
    if (newStudentIds.length === 0) return;

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
// FUNCIÓN 5: NOTIFICAR SOBRE ASIGNACIÓN DE EVENTO
// ===============================================================================================
exports.onEventAssigned = onDocumentWritten(
  "/schools/{schoolId}/events/{eventId}",
  async (event) => {
    if (!event.data?.before.exists || !event.data?.after.exists) return;
    const beforeData = event.data.before.data();
    const afterData = event.data.after.data();
    if (!beforeData || !afterData) return;

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
