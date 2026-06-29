const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

const db = admin.firestore();

exports.onUserDeleted = functions.auth.user().onDelete(async (user) => {
  await db.doc("user/" + user.uid).delete();
});

/**
 * Sends a push notification to all admin users when a new booking is created.
 */
exports.notifyAdminsOnNewBooking = functions.firestore
  .document("order/{orderId}")
  .onCreate(async (snap, context) => {
    const data = snap.data() || {};
    const orderId = context.params.orderId;

    if (data.halh_order === "Canceled") {
      return null;
    }

    const orderNumber = data.IDorder || orderId;
    const customerName = data.naim_user_text || "عميل";
    const total = data.total != null ? String(data.total) : "";

    const countryRef = data.Rev_dolh;

    const tokenSet = new Set();
    const adminDocs = [];

    const superAdminsSnap = await db
      .collection("user")
      .where("IsAdmin", "==", true)
      .get();
    superAdminsSnap.forEach((doc) => adminDocs.push(doc));
    superAdminsSnap.forEach((doc) => collectTokens(doc, tokenSet));

    if (countryRef) {
      const agentsSnap = await db
        .collection("user")
        .where("Isagent", "==", true)
        .where("Rev_dloh_agent", "==", countryRef)
        .get();
      agentsSnap.forEach((doc) => adminDocs.push(doc));
      agentsSnap.forEach((doc) => collectTokens(doc, tokenSet));
    }

    const tokens = Array.from(tokenSet);
    if (tokens.length === 0) {
      console.log("No admin FCM tokens registered.");
      return null;
    }

    const body =
      total.length > 0
        ? `حجز #${orderNumber} من ${customerName} — ${total} ريال`
        : `حجز #${orderNumber} من ${customerName} بانتظار الموافقة`;

    const message = {
      notification: {
        title: "حجز جديد",
        body: body,
      },
      data: {
        type: "new_booking",
        orderId: orderId,
        click_action: "FLUTTER_NOTIFICATION_CLICK",
      },
      android: {
        priority: "high",
        notification: {
          channelId: "admin_bookings",
          clickAction: "FLUTTER_NOTIFICATION_CLICK",
        },
      },
      apns: {
        payload: {
          aps: {
            sound: "default",
            badge: 1,
          },
        },
      },
      tokens: tokens,
    };

    const response = await admin.messaging().sendEachForMulticast(message);
    console.log(
      `Booking ${orderId}: sent ${response.successCount}/${tokens.length}`,
    );

    if (response.failureCount > 0) {
      const invalidTokens = [];
      response.responses.forEach((res, index) => {
        if (!res.success) {
          invalidTokens.push(tokens[index]);
        }
      });
      await cleanupInvalidTokens(adminDocs, invalidTokens);
    }

    return null;
  });

function collectTokens(doc, tokenSet) {
  const user = doc.data();
  if (user.fcm_token) {
    tokenSet.add(user.fcm_token);
  }
  (user.fcm_tokens || []).forEach((token) => {
    if (token) tokenSet.add(token);
  });
}

async function cleanupInvalidTokens(adminDocs, invalidTokens) {
  if (!invalidTokens.length) return;

  const batch = db.batch();
  let writes = 0;

  adminDocs.forEach((doc) => {
    const data = doc.data();
    const current = new Set(
      [data.fcm_token, ...(data.fcm_tokens || [])].filter(Boolean),
    );
    let changed = false;

    invalidTokens.forEach((bad) => {
      if (current.delete(bad)) changed = true;
    });

    if (!changed) return;

    const remaining = Array.from(current);
    const update = { fcm_tokens: remaining };
    if (remaining.length > 0) {
      update.fcm_token = remaining[remaining.length - 1];
    } else {
      update.fcm_token = admin.firestore.FieldValue.delete();
    }

    batch.update(doc.ref, update);
    writes++;
  });

  if (writes > 0) {
    await batch.commit();
  }
}
