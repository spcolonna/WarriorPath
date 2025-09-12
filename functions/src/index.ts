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
// --- REEMPLAZA TU onMemberStatusChange EXISTENTE POR ESTA VERSIÓN AMPLIADA ---

/**
 * Se activa cuando se crea o actualiza un documento en cualquier subcolección 'members'.
 * - Notifica al dueño cuando un alumno se postula.
 * - Notifica al alumno cuando es aceptado.
 * - Notifica al alumno cuando es promovido de nivel.
 * - Notifica al alumno cuando se le asignan nuevas técnicas.
 */
exports.onMemberStatusChange = onDocumentWritten("/schools/{schoolId}/members/{memberId}", async (event) => {
    if (!event.data) {
        logger.warn("No data found in the event trigger. Exiting function.");
        return;
    }

    const schoolId = event.params.schoolId;
    const memberId = event.params.memberId;

    const beforeData = event.data.before.data();
    const afterData = event.data.after.data();

    // Escenario 1: Creación de Miembro (Postulación)
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

    // Escenario 2: Actualización de Miembro (Aceptación, Promoción, Técnicas)
    if (event.data.before.exists && event.data.after.exists && beforeData && afterData) {
        // 2a: Notificación de Aceptación
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
                logger.error("Error al notificar al alumno aceptado:", error);
            }
        }

        // 2b: Notificación de Promoción de Nivel
        // Usamos el flag 'hasUnseenPromotion' que tu app ya establece.
        if (beforeData.hasUnseenPromotion === false && afterData.hasUnseenPromotion === true) {
            logger.info(`Miembro [${memberId}] ha sido promovido en [${schoolId}].`);
            try {
                const newLevelId = afterData.currentLevelId;
                let newLevelName = "un nuevo nivel";
                if (newLevelId) {
                    const levelDoc = await db.collection("schools").doc(schoolId).collection("levels").doc(newLevelId).get();
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

        // 2c: Notificación de Nuevas Técnicas Asignadas
        const beforeTechs = new Set(beforeData.assignedTechniqueIds ?? []);
        const afterTechs = afterData.assignedTechniqueIds ?? [];
        const newTechIds = afterTechs.filter((id: string) => !beforeTechs.has(id));

        if (newTechIds.length > 0) {
            logger.info(`Nuevas técnicas asignadas a [${memberId}].`);
            try {
                const payload = {
                    notification: {
                        title: "Nuevas Técnicas Asignadas",
                        body: `Tu maestro te ha asignado ${newTechIds.length} nueva(s) técnica(s) para practicar. ¡Revísalas en tu progreso!`,
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

// ===============================================================================================
// FUNCIÓN 4: NOTIFICAR SOBRE NUEVO PAGO REGISTRADO
// ===============================================================================================
/**
 * Se activa cuando se crea un nuevo documento de pago para un miembro.
 * Notifica al alumno correspondiente.
 */
exports.onPaymentCreated = onDocumentWritten("/schools/{schoolId}/members/{studentId}/payments/{paymentId}", async (event) => {
    if (!event.data?.after.exists || event.data.before.exists) {
        return;
    }

    const paymentData = event.data.after.data();
    const studentId = event.params.studentId;

    if (!paymentData) {
        logger.error("No hay datos en el nuevo documento de pago.");
        return;
    }

    logger.info(`Nuevo pago registrado para [${studentId}]. Notificando...`);

    const amount = paymentData.amount ?? 0;
    const currency = paymentData.currency ?? "";
    const concept = paymentData.concept ?? "un pago";

    const payload = {
        notification: {
            title: "Nuevo Pago Registrado",
            body: `Tu maestro ha registrado un pago de ${amount} ${currency} por concepto de "${concept}".`,
        },
    };

    try {
        await sendNotificationsToUser(studentId, payload);
    } catch (error) {
        logger.error(`Error al notificar sobre nuevo pago a ${studentId}:`, error);
    }
});


// ===============================================================================================
// FUNCIÓN 5: NOTIFICAR SOBRE NUEVA ASISTENCIA REGISTRADA
// ===============================================================================================
/**
 * Se activa cuando se actualiza un registro de asistencia.
 * Compara la lista de alumnos presentes antes y después del cambio,
 * y notifica a los alumnos que fueron recién añadidos.
 */
exports.onAttendanceUpdated = onDocumentWritten("/schools/{schoolId}/attendanceRecords/{recordId}", async (event) => {
    if (!event.data?.before.exists || !event.data?.after.exists) {
        // Solo nos interesan las actualizaciones, no creaciones o borrados
        return;
    }

    const beforeData = event.data.before.data();
    const afterData = event.data.after.data();

    if (!beforeData || !afterData) {
        logger.warn("Faltan datos en el evento de actualización de asistencia.");
        return;
    }

    const beforeStudentIds = new Set(beforeData.presentStudentIds ?? []);
    const afterStudentIds = afterData.presentStudentIds ?? [];

    // Encontramos los alumnos que fueron recién añadidos
    const newStudentIds: string[] = afterStudentIds.filter((id: string) => !beforeStudentIds.has(id));

    if (newStudentIds.length === 0) {
        // No se añadieron nuevos alumnos, no hay a quién notificar.
        return;
    }

    logger.info(`Nuevas asistencias registradas para los alumnos: [${newStudentIds.join(", ")}]. Notificando...`);

    const scheduleTitle = afterData.scheduleTitle ?? "una clase";
    const payload = {
        notification: {
            title: "Asistencia Registrada",
            body: `¡Presente! Se ha registrado tu asistencia para la clase de "${scheduleTitle}".`,
        },
    };

    // Enviamos una notificación a cada uno de los nuevos alumnos
    const notificationPromises = newStudentIds.map((studentId) =>
        sendNotificationsToUser(studentId, payload)
    );

    try {
        await Promise.all(notificationPromises);
    } catch(error) {
        logger.error("Error enviando notificaciones de asistencia:", error);
    }
});
