/**
 * Borrado definitivo programado de cuentas de CicloPlus marcadas como
 * "pendientes de borrado" hace más de 30 días.
 *
 * Contexto: cuando alguien pulsa "Borrar cuenta" en la app (ver
 * lib/services/auth_service.dart → requestAccountDeletion), la app YA NO
 * borra nada al instante. Solo marca su documento `users/{uid}` con
 * `pendingDeletion: true` y `deletionRequestedAt: <ISO string>`, y cierra
 * sesión. Si esa persona vuelve a iniciar sesión con la misma cuenta dentro
 * de 30 días, AuthGate le ofrece recuperarla (AccountPendingDeletionScreen
 * → AuthService.cancelAccountDeletion, que borra esas dos marcas).
 *
 * Esta función corre sola una vez al día, busca las cuentas cuyo plazo de
 * gracia ya venció (deletionRequestedAt hace 30 días o más) y SOLO
 * entonces borra de verdad: todo el árbol de Firestore bajo ese usuario
 * (el documento `users/{uid}` y todas sus subcolecciones — days, pregnancy,
 * cycle, partners, reconnectRequests, etc., vía recursiveDelete) y la
 * cuenta en Firebase Authentication. A partir de ahí ya no hay forma de
 * recuperarla — exactamente lo que se le explica a la usuaria en el diálogo
 * de confirmación antes de pedir el borrado.
 *
 * DESPLIEGUE: esta carpeta no se puede desplegar desde el entorno donde se
 * escribió este código (sin acceso de red a Firebase). Para activarla,
 * ejecutar desde una máquina con Firebase CLI y sesión iniciada
 * (`firebase login`) en la raíz del repo:
 *
 *   cd functions && npm install
 *   firebase deploy --only functions
 *
 * No requiere configuración adicional: usa las credenciales por defecto
 * del proyecto (`cicloplus-9a957`, ver .firebaserc) vía
 * `admin.initializeApp()` sin argumentos.
 */

const { onSchedule } = require('firebase-functions/v2/scheduler');
const admin = require('firebase-admin');

admin.initializeApp();

const GRACE_DAYS = 30;
const USERS_COLLECTION = 'users';

exports.purgeExpiredAccountDeletions = onSchedule('every 24 hours', async () => {
  const db = admin.firestore();
  const auth = admin.auth();

  const cutoff = new Date();
  cutoff.setDate(cutoff.getDate() - GRACE_DAYS);
  const cutoffIso = cutoff.toISOString();

  // `deletionRequestedAt` se guarda como string ISO 8601 (ver
  // AuthService.requestAccountDeletion) — la comparación de strings
  // funciona correctamente para fechas ISO porque son lexicográficamente
  // ordenables.
  const snapshot = await db
    .collection(USERS_COLLECTION)
    .where('pendingDeletion', '==', true)
    .where('deletionRequestedAt', '<=', cutoffIso)
    .get();

  if (snapshot.empty) {
    console.log('purgeExpiredAccountDeletions: no hay cuentas vencidas hoy.');
    return;
  }

  console.log(`purgeExpiredAccountDeletions: ${snapshot.size} cuenta(s) vencida(s), borrando...`);

  for (const doc of snapshot.docs) {
    const uid = doc.id;
    try {
      // Borra el documento del usuario Y TODAS sus subcolecciones (days,
      // pregnancy, cycle, partners, reconnectRequests, etc.) en un solo
      // paso — no hace falta enumerarlas a mano ni mantener esta lista
      // sincronizada si en el futuro se añade alguna subcolección nueva.
      await db.recursiveDelete(doc.ref);
      // Borra también la cuenta de Firebase Authentication — si ya no
      // existe (por ejemplo si se borró a mano antes), se ignora el error
      // en vez de dejar el resto del bucle sin procesar.
      try {
        await auth.deleteUser(uid);
      } catch (authError) {
        if (authError.code !== 'auth/user-not-found') {
          console.error(`purgeExpiredAccountDeletions: fallo borrando Auth de ${uid}:`, authError);
        }
      }
      console.log(`purgeExpiredAccountDeletions: cuenta ${uid} borrada definitivamente.`);
    } catch (error) {
      // Si una cuenta falla, se sigue con las demás — se reintentará esta
      // misma cuenta en la próxima ejecución diaria (sigue marcada como
      // pendingDeletion hasta que el borrado se complete con éxito).
      console.error(`purgeExpiredAccountDeletions: fallo borrando ${uid}:`, error);
    }
  }
});
