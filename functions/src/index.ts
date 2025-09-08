// Importa todo lo necesario (ya deberías tenerlos si ejecutaste npm install)
import {onSchedule} from "firebase-functions/v2/scheduler";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";

// Inicializa Firebase Admin (si no lo tienes ya en tu index.ts/js)
admin.initializeApp();
const db = admin.firestore();

/**
 * Función programada para ejecutarse el día 1 de cada mes a las 9:00 AM
 * Zona Horaria: America/Montevideo (AJUSTA ESTO A TU ZONA HORARIA DESEADA)
 *
 * Esta función genera las facturas/recordatorios pendientes para todos los alumnos activos
 * que tengan un plan de pago asignado y que NO tengan ya un recordatorio pendiente.
 */
exports.generateMonthlyPaymentReminders = onSchedule(
  {
    schedule: "0 9 1 * *", // 9:00 AM del día 1 de cada mes.
    timeZone: "America/Montevideo", // ¡IMPORTANTE! Ajusta esto a tu zona horaria.
  },
  // FIX 1: 'event' renombrado a '_event' porque no se usa.
  async (_event) => {
    logger.info("Iniciando la generación de recordatorios de pago mensuales...");

    const membersQuery = db.collectionGroup("members")
      .where("status", "==", "active")
      .where("assignedPaymentPlanId", "!=", null);

    const activeMembersSnap = await membersQuery.get();

    // Corrección de .isEmpty a .empty (que ya hiciste)
    if (activeMembersSnap.empty) {
      logger.info("No se encontraron miembros activos con planes asignados.");
      return;
    }

    logger.info(`Encontrados ${activeMembersSnap.size} miembros para procesar.`);

    // FIX 2: Cambiamos Promise<any> por Promise<void>
    const promises: Promise<void>[] = [];

    for (const memberDoc of activeMembersSnap.docs) {
      const memberData = memberDoc.data();
      const memberId = memberDoc.id;

      const schoolId = memberDoc.ref.parent.parent?.id;

      if (!schoolId) {
        logger.warn(`No se pudo obtener SchoolID para el miembro ${memberId}`);
        continue;
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

        // Corrección de .isEmpty a .empty (que ya hiciste)
        if (pendingRemindersSnap.empty) {
          logger.info(`Generando nuevo recordatorio para miembro ${memberId} (Plan: ${planId}).`);

          const planDoc = await db.collection("schools").doc(schoolId)
            .collection("paymentPlans").doc(planId).get();

          if (!planDoc.exists) {
            logger.error(`Error: El Plan ${planId} asignado al miembro ${memberId} NO EXISTE.`);
            return;
          }

          // FIX 3: Eliminamos el '!' (non-null assertion) y añadimos un type guard (chequeo)
          const planData = planDoc.data();

          if (!planData) {
            logger.error(`Error: El Plan ${planId} existe pero no tiene data.`);
            return;
          }

          const reminderData = {
            concept: planData.title, // Ahora es seguro acceder
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

          await sendNotificationToUser(memberId, planData.title);
        } else {
          logger.info(`Miembro ${memberId} ya tiene un pago pendiente. Omitiendo.`);
        }
      };

      promises.push(processingPromise());
    }

    await Promise.all(promises);
    logger.info("Proceso de generación de recordatorios completado.");
  }
);


// FIX 4 y 5: Agregamos el bloque de comentarios JSDoc que exigen las reglas del linter.
/**
 * Función Auxiliar para enviar Notificaciones Push (FCM)
 * @param {string} userId El ID del usuario (miembro) a notificar.
 * @param {string} concept El concepto del pago (nombre del plan) para el body.
 */
async function sendNotificationToUser(userId: string, concept: string) {
  try {
    const userDoc = await db.collection("users").doc(userId).get();
    if (!userDoc.exists) {
      logger.warn(`Usuario ${userId} no encontrado en /users. No se puede notificar.`);
      return;
    }

    const fcmToken = userDoc.data()?.fcmToken;

    if (fcmToken) {
      const payload = {
        notification: {
          title: "Recordatorio de Pago",
          body: `Tu pago de ${concept} está listo. Revisa la app para más detalles.`,
        },
        token: fcmToken,
      };

      logger.info(`Enviando notificación a ${userId}`);
      await admin.messaging().send(payload);
    } else {
      logger.warn(`Usuario ${userId} no tiene un fcmToken. No se puede notificar.`);
    }
  } catch (error) {
    logger.error(`Error enviando notificación a ${userId}:`, error);
  }
}
