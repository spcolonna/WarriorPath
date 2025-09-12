import {onSchedule} from "firebase-functions/v2/scheduler";
import {onDocumentWritten} from "firebase-functions/v2/firestore";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";

// Inicializa Firebase Admin
admin.initializeApp();
const db = admin.firestore();

// ===============================================================================================
// FUNCIÓN 1: GENERAR RECORDATORIOS DE PAGO MENSUALES (Sintaxis v2)
// ===============================================================================================
exports.generateMonthlyPaymentReminders = onSchedule(
  {
    schedule: "0 9 1 * *",
    timeZone: "America/Montevideo",
  },
  async (event) => {
    logger.info("Iniciando la generación de recordatorios de pago mensuales...");

    const membersQuery = db.collectionGroup("members")
      .where("status", "==", "active")
      .where("assignedPaymentPlanId", "!=", null);

    const activeMembersSnap = await membersQuery.get();

    if (activeMembersSnap.empty) {
      logger.info("No se encontraron miembros activos con planes asignados.");
      return;
    }

    logger.info(`Encontrados ${activeMembersSnap.size} miembros para procesar.`);
    const promises: Promise<void>[] = [];

    activeMembersSnap.docs.forEach((memberDoc) => {
      const memberData = memberDoc.data();
      const memberId = memberDoc.id;
      const schoolId = memberDoc.ref.parent.parent?.id;

      if (!schoolId) {
        logger.warn(`No se pudo obtener SchoolID para el miembro ${memberId}`);
        return;
      }

      const planId = memberData.assignedPaymentPlanId;

      const processingPromise = async () => {
        const pendingRemindersSnap = await db
          .collection("schools").doc(schoolId)
          .collection("members").doc(memberId)
          .collection("paymentReminders")
          .where("status", "==", "pending")
          .limit(1)
          .get();

        if (pendingRemindersSnap.empty) {
          logger.info(`Generando nuevo recordatorio para miembro ${memberId}.`);

          const planDoc = await db.collection("schools").doc(schoolId)
            .collection("paymentPlans").doc(planId).get();

          const planData = planDoc.data();
          if (!planDoc.exists || !planData) {
            logger.error(`Plan ${planId} no existe o no tiene datos.`);
            return;
          }

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
        } else {
          logger.info(`Miembro ${memberId} ya tiene un pago pendiente. Omitiendo.`);
        }
      };
      promises.push(processingPromise());
    });

    await Promise.all(promises);
    logger.info("Proceso de recordatorios completado.");
  });

// ===============================================================================================
// FUNCIÓN 2: NOTIFICAR SOBRE POSTULACIONES Y ACEPTACIONES (Sintaxis v2)
// ===============================================================================================
exports.onMemberStatusChange = onDocumentWritten("/schools/{schoolId}/members/{memberId}", async (event) => {
  if (!event.data) {
    logger.warn("No data found in the event trigger. Exiting function.");
    return;
  }

  const schoolId = event.params.schoolId;
  const memberId = event.params.memberId;

  const beforeData = event.data.before.data();
  const afterData = event.data.after.data();

  // Escenario 1: Nuevo Miembro se Postula
  if (!event.data.before.exists && event.data.after.exists && afterData) {
    if (afterData.status === "pending") {
      logger.info(`Nuevo miembro [${memberId}] pendiente en [${schoolId}].`);
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
    return;
  }

  // Escenario 2: Estado del Miembro Cambia
  if (event.data.before.exists && event.data.after.exists && beforeData && afterData) {
    if (beforeData.status === "pending" && afterData.status === "active") {
      logger.info(`Miembro [${memberId}] aceptado en [${schoolId}].`);
      try {
        const schoolDoc = await db.collection("schools").doc(schoolId).get();
        const schoolName = schoolDoc.data()?.name ?? "tu escuela";
        const payload = {
          notification: {
            title: "¡Has sido Aceptado!",
            body: `Felicitaciones, tu solicitud para unirte a ${schoolName} ha sido aprobada.`,
          },
        };
        await sendNotificationsToUser(memberId, payload);
      } catch (error) {
        logger.error("Error al notificar al alumno:", error);
      }
    }
    return;
  }
});

// ===============================================================================================
// FUNCIÓN 3: FUNCIÓN AUXILIAR PARA ENVIAR NOTIFICACIONES (VERSIÓN COMPATIBLE)
// ===============================================================================================
/**
 * Envía notificaciones a los tokens de un usuario.
 * @param {string} userId El ID del usuario.
 * @param {object} payload El contenido de la notificación.
 */
async function sendNotificationsToUser(userId: string, payload: {notification: {title: string, body: string}}) {
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
        notification: payload.notification,
      };

      const response = await admin.messaging().sendEachForMulticast(message);

      const tokensToRemove: Promise<FirebaseFirestore.WriteResult>[] = [];
      response.responses.forEach((result: admin.messaging.SendResponse, index: number) => {
        if (!result.success) {
          const error = result.error;
          logger.error(`Fallo al enviar a token ${tokens[index]}`, error);
          if (error) {
            logger.error(`Fallo al enviar notificación a ${tokens[index]}`, error);
            if (error.code === "messaging/invalid-registration-token" ||
                            error.code === "messaging/registration-token-not-registered") {
              tokensToRemove.push(db.collection("users").doc(userId).update({
                fcmTokens: admin.firestore.FieldValue.arrayRemove(tokens[index]),
              }));
            }
          }
        }
      });
      await Promise.all(tokensToRemove);
    } else {
      logger.warn(`Usuario ${userId} no tiene fcmTokens.`);
    }
  } catch (error) {
    logger.error(`Error enviando notificaciones a ${userId}:`, error);
  }
}
