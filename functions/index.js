const { onDocumentCreated, onDocumentUpdated, onDocumentDeleted } = require("firebase-functions/v2/firestore");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const admin = require("firebase-admin");

admin.initializeApp();

/**
 * Yardımcı Fonksiyon: Bildirim gönder ve Firestore'a kaydet.
 * Eğer kullanıcının "email" alanı doluysa, Push Notification GÖNDERİLMEZ (Sadece Firestore'a kaydedilir).
 */
async function sendNotificationAndLog({ userId, title, body, type, relatedId, dataPayload, tag, link }) {
  try {
    const userDoc = await admin.firestore().collection("users").doc(userId).get();
    if (!userDoc.exists) return;

    const userData = userDoc.data();
    const fcmToken = userData.fcmToken;
    const hasEmail = userData.email && userData.email.trim() !== "";

    // E-posta adresi yoksa VE fcmToken varsa push notification at
    if (fcmToken && !hasEmail) {
      const message = {
        token: fcmToken,
        notification: { title, body },
        android: {
          priority: "high",
          notification: {
            channelId: "sayim_notifications",
            tag: tag
          }
        },
        webpush: {
          headers: { 
            Topic: tag,
            Urgency: "high"
          },
          fcmOptions: { link: link || "https://lnyctophilia.github.io/WP_Sayim/?open_notifications=true" }
        },
        apns: {
          headers: { 
            "apns-collapse-id": tag,
            "apns-priority": "10"
          },
          payload: {
            aps: {
              sound: "default",
              badge: 1,
              "content-available": 1
            }
          }
        },
        data: dataPayload
      };
      
      try {
        await admin.messaging().send(message);
        
        // Push başarılı — son gönderim zamanını kaydet (keep-alive takibi için)
        await admin.firestore().collection("users").doc(userId).update({
          lastPushSentAt: admin.firestore.FieldValue.serverTimestamp()
        });
      } catch (e) {
        console.error("Error sending push notification:", e);
        
        // ─── GEÇERSİZ TOKEN OTOMATİK TEMİZLEME ───
        // iOS subscription sessizce expire/invalidate olduğunda veya cihaz değiştiğinde
        // Firebase bu hata kodlarını döner. Token artık işe yaramıyorsa Firestore'dan sil,
        // kullanıcı bir sonraki uygulama açılışında yeni token üretecek.
        const invalidTokenCodes = [
          'messaging/registration-token-not-registered',
          'messaging/invalid-registration-token',
          'messaging/third-party-auth-error',
          'messaging/mismatched-credential'
        ];
        
        if (e.code && invalidTokenCodes.includes(e.code)) {
          console.log(`[TOKEN CLEANUP] Geçersiz token siliniyor. userId: ${userId}, hata: ${e.code}`);
          try {
            await admin.firestore().collection("users").doc(userId).update({
              fcmToken: admin.firestore.FieldValue.delete(),
              fcmTokenInvalidatedAt: admin.firestore.FieldValue.serverTimestamp(),
              fcmTokenInvalidReason: e.code
            });
          } catch (cleanupErr) {
            console.error("[TOKEN CLEANUP] Token silinirken hata:", cleanupErr);
          }
        }
      }
    }

    // Uygulama içi bildirimi her zaman kaydet
    await admin.firestore().collection("notifications").add({
      userId: userId,
      title: title,
      body: body,
      type: type,
      relatedId: relatedId || "",
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      isRead: false
    });
  } catch (error) {
    console.error("Error in sendNotificationAndLog:", error);
  }
}

/**
 * Yardımcı Fonksiyon: EmailJS ile e-posta gönder (Firebase Mail Extension yerine).
 */
async function sendEmailJSEmail(toEmail, subject, textContent) {
  try {
    const response = await fetch('https://api.emailjs.com/api/v1.0/email/send', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        service_id: 'service_qjvatbn',
        template_id: 'template_9wd7j5s',
        user_id: '6Ybd1Uu2O5Es_Rdtq',
        accessToken: process.env.EMAILJS_PRIVATE_KEY,
        template_params: {
          to_email: toEmail,
          subject: subject,
          message: textContent
        }
      }),
    });

    if (response.ok) {
      console.log(`[EmailJS] Successfully sent email to ${toEmail}`);
    } else {
      const errorText = await response.text();
      console.error(`[EmailJS] Error sending email to ${toEmail}:`, errorText);
    }
  } catch (error) {
    console.error(`[EmailJS] Exception while sending email to ${toEmail}:`, error);
  }
}

// 1. Yeni davet oluşturulduğunda personeli bilgilendir
exports.sendDavetNotification = onDocumentCreated("davetler/{davetId}", async (event) => {
  const davetData = event.data.data();
  if (!davetData) return;

  if (davetData.isPast === true) {
    console.log(`Davet notification skipped: Past sayim (davet ${event.params.davetId}).`);
    return;
  }

  const staffId = davetData.userId;
  const sayimId = davetData.sayimId;
  
  if (!staffId) {
    console.log("No userId in davet document.");
    return;
  }

  try {
    const sayimDoc = await admin.firestore().collection("sayimlar").doc(sayimId).get();
    if (!sayimDoc.exists) return;

    const sayimData = sayimDoc.data();
    
    if (sayimData.status === "closed") {
      console.log(`Davet notification skipped: Sayim is closed (${sayimId}).`);
      return;
    }

    const sayimName = sayimData.toplanmaYeri || "Yeni Sayım";
    const creatorId = sayimData.createdBy;

    if (staffId === creatorId) {
      console.log(`Davet notification skipped: Creator ${creatorId} added themselves.`);
      return;
    }

    await sendNotificationAndLog({
      userId: staffId,
      title: "Yeni Sayım Daveti",
      body: `Seni "${sayimName}" isimli sayıma davet ettiler. Lütfen uygulamaya girip onay ver.`,
      type: "davet",
      relatedId: event.params.davetId,
      dataPayload: {
        type: "davet",
        davetId: event.params.davetId,
        sayimId: sayimId
      },
      tag: `davet_${event.params.davetId}`
    });
  } catch (error) {
    console.error("Error processing sendDavetNotification:", error);
  }
});

// 2. Davet durumu (kabul/red) değiştiğinde sayımı oluşturan kişiyi bilgilendir
exports.sendDavetResponseNotification = onDocumentUpdated("davetler/{davetId}", async (event) => {
  const oldData = event.data.before.data();
  const newData = event.data.after.data();

  if (!oldData || !newData) return;
  if (newData.isPast === true) return;
  if (oldData.status === newData.status) return;
  if (newData.status === "pending") return;

  const staffId = newData.userId;
  const sayimId = newData.sayimId;
  const statusStr = newData.status === "accepted" ? "kabul etti" : "reddetti";

  try {
    const sayimDoc = await admin.firestore().collection("sayimlar").doc(sayimId).get();
    if (!sayimDoc.exists) return;
    const sayimData = sayimDoc.data();
    const sayimName = sayimData.toplanmaYeri || "Bilinmeyen Sayım";
    const creatorId = sayimData.createdBy;

    if (staffId === creatorId) return;

    const staffDoc = await admin.firestore().collection("users").doc(staffId).get();
    const staffName = staffDoc.exists ? (staffDoc.data().fullName || "Bir personel") : "Bir personel";

    await sendNotificationAndLog({
      userId: creatorId,
      title: "Davet Yanıtı",
      body: `${staffName}, "${sayimName}" sayım davetini ${statusStr}.`,
      type: "davet_response",
      relatedId: event.params.davetId,
      dataPayload: {
        type: "davet_response",
        davetId: event.params.davetId,
        sayimId: sayimId
      },
      tag: `davet_response_${event.params.davetId}`
    });
  } catch (error) {
    console.error("Error processing sendDavetResponseNotification:", error);
  }
});

// 2.5 Davete hatırlatma gönderildiğinde personeli bilgilendir
exports.sendDavetReminderNotification = onDocumentUpdated("davetler/{davetId}", async (event) => {
  const oldData = event.data.before.data();
  const newData = event.data.after.data();

  if (!oldData || !newData) return;

  const oldReminder = oldData.lastReminderAt ? oldData.lastReminderAt.toMillis() : null;
  const newReminder = newData.lastReminderAt ? newData.lastReminderAt.toMillis() : null;

  if (!newReminder || oldReminder === newReminder) return;

  const staffId = newData.userId;
  const sayimId = newData.sayimId;

  try {
    const sayimDoc = await admin.firestore().collection("sayimlar").doc(sayimId).get();
    const sayimName = sayimDoc.exists ? (sayimDoc.data().toplanmaYeri || "Sayım") : "Sayım";

    await sendNotificationAndLog({
      userId: staffId,
      title: "Yeni Sayım Daveti",
      body: `Seni "${sayimName}" isimli sayıma davet ettiler. Lütfen uygulamaya girip onay ver.`,
      type: "davet_reminder",
      relatedId: event.params.davetId,
      dataPayload: {
        type: "davet",
        davetId: event.params.davetId,
        sayimId: sayimId
      },
      tag: `davet_${event.params.davetId}`
    });
  } catch (error) {
    console.error("Error processing sendDavetReminderNotification:", error);
  }
});

// 3. Davet iptal edildiğinde (silindiğinde) personeli bilgilendir
exports.sendDavetCancelledNotification = onDocumentDeleted("davetler/{davetId}", async (event) => {
  const davetData = event.data.data();
  if (!davetData) return;
  if (davetData.status !== "accepted") return;
  if (davetData.silentDelete === true) return;

  const staffId = davetData.userId;
  const sayimId = davetData.sayimId;

  try {
    const sayimDoc = await admin.firestore().collection("sayimlar").doc(sayimId).get();
    const sayimName = sayimDoc.exists ? (sayimDoc.data().toplanmaYeri || "Sayım") : "Sayım";

    await sendNotificationAndLog({
      userId: staffId,
      title: "Sayım İptali",
      body: `Kabul ettiğin "${sayimName}" isimli sayım iptal edildi.`,
      type: "davet_cancelled",
      relatedId: sayimId,
      dataPayload: {
        type: "davet_cancelled",
        sayimId: sayimId
      },
      tag: `davet_${event.params.davetId}`
    });
  } catch (error) {
    console.error("Error processing sendDavetCancelledNotification:", error);
  }
});

// 4. Kullanıcı dokümanı (AppUser) güncellendiğinde Firebase Auth'u senkronize et
exports.syncUserWithAuth = onDocumentUpdated("users/{userId}", async (event) => {
  const oldData = event.data.before.data();
  const newData = event.data.after.data();

  if (!oldData || !newData) return;

  const updatePayload = {};

  if (newData.password) {
    updatePayload.password = newData.password;
  }

  if (oldData.fullName !== newData.fullName) {
    updatePayload.displayName = newData.fullName;
  }

  if (oldData.username !== newData.username && newData.username) {
    updatePayload.email = `${newData.username.trim().toLowerCase()}@wpsayim.local`;
  }

  if (Object.keys(updatePayload).length > 0) {
    try {
      await admin.auth().updateUser(event.params.userId, updatePayload);
      console.log(`Successfully synced auth for user: ${event.params.userId}`);
      
      if (updatePayload.password) {
        await admin.firestore().collection("users").doc(event.params.userId).update({
          password: admin.firestore.FieldValue.delete()
        });
        console.log(`Deleted plaintext password from Firestore for user: ${event.params.userId}`);
      }
    } catch (error) {
      console.error(`Error syncing auth for user: ${event.params.userId}`, error);
    }
  }
});

// 5. Kullanıcı dokümanı (AppUser) silindiğinde Firebase Auth'tan da sil
exports.deleteUserFromAuth = onDocumentDeleted("users/{userId}", async (event) => {
  const userId = event.params.userId;
  try {
    await admin.auth().deleteUser(userId);
    console.log(`Successfully deleted auth user: ${userId}`);
  } catch (error) {
    if (error.code === 'auth/user-not-found') {
      console.log(`Auth user ${userId} already deleted or does not exist.`);
    } else {
      console.error(`Error deleting auth user: ${userId}`, error);
    }
  }
});

// 6. Sayım Hatırlatıcı (Her 1 saatte bir çalışır, 3 saat kalanlara bildirim atar)
exports.sayimAutoReminder = onSchedule("every 60 minutes", async (event) => {
  const nowMs = Date.now();
  
  const sayimlarSnap = await admin.firestore().collection("sayimlar")
    .where("status", "==", "open")
    .get();

  if (sayimlarSnap.empty) return;

  for (const sayimDoc of sayimlarSnap.docs) {
    const sayimData = sayimDoc.data();
    if (!sayimData || !sayimData.date || !sayimData.gruplar) continue;
    
    const davetlerSnap = await admin.firestore().collection("davetler")
      .where("sayimId", "==", sayimDoc.id)
      .where("status", "==", "accepted")
      .get();

    if (davetlerSnap.empty) continue;

    for (const davetDoc of davetlerSnap.docs) {
      const davet = davetDoc.data();
      
      if (davet.autoReminderSent === true) continue;

      const grup = sayimData.gruplar.find(g => g.grupId === davet.grupId);
      if (!grup || !grup.saat) continue;

      const sayimDateObj = sayimData.date.toDate();
      const trtDateMs = sayimDateObj.getTime() + (3 * 60 * 60 * 1000); 
      const trtDateObj = new Date(trtDateMs);
      
      const year = trtDateObj.getUTCFullYear();
      const month = String(trtDateObj.getUTCMonth() + 1).padStart(2, '0');
      const day = String(trtDateObj.getUTCDate()).padStart(2, '0');
      
      const isoString = `${year}-${month}-${day}T${grup.saat}:00+03:00`;
      const finalSayimDate = new Date(isoString);

      const diffHours = (finalSayimDate.getTime() - nowMs) / (1000 * 60 * 60);

      if (diffHours > 0 && diffHours <= 3) {
        const userDoc = await admin.firestore().collection("users").doc(davet.userId).get();
        if (!userDoc.exists) continue;
        
        const userData = userDoc.data();
        if (userData.sayimReminderEnabled === false) continue;

        const sayimName = sayimData.toplanmaYeri || "Sayım";
        
        await sendNotificationAndLog({
          userId: davet.userId,
          title: "Yaklaşan Sayım",
          body: `Bugün saat ${grup.saat}'te "${sayimName}" sayımı var. Lütfen vaktinde orada olun.`,
          type: "sayim_auto_reminder",
          relatedId: davetDoc.id,
          dataPayload: {
            type: "sayim_auto_reminder",
            davetId: davetDoc.id,
            sayimId: sayimDoc.id
          },
          tag: `sayim_auto_reminder_${davetDoc.id}`
        });
        
        try {
          await davetDoc.ref.update({ autoReminderSent: true });
        } catch (e) {
          console.error("Error updating autoReminderSent for davet " + davetDoc.id, e);
        }
      }
    }
  }
});

// 7. Kullanıcı onaylandığında bildirim gönder
exports.sendApprovalNotification = onDocumentUpdated("users/{userId}", async (event) => {
  const oldData = event.data.before.data();
  const newData = event.data.after.data();

  if (!oldData || !newData) return;

  console.log(`[sendApprovalNotification TRIGGER] User: ${event.params.userId} | old isApproved: ${oldData.isApproved}, new isApproved: ${newData.isApproved} | old email: ${oldData.email}, new email: ${newData.email}`);

  const wasApproved = oldData.isApproved === true;
  const isNowApproved = newData.isApproved === true;

  if (!wasApproved && isNowApproved) {
    const email = newData.email || "";
    const hasEmail = email.trim() !== "";

    console.log(`[sendApprovalNotification] User ${event.params.userId} approved. hasEmail: ${hasEmail}, email: '${email}'`);

    if (hasEmail) {
      // E-posta adresi olan kullanıcıya e-posta gönder
      await sendEmailJSEmail(
        email.trim(),
        "WP Sayım - Hesabınız Onaylandı!",
        "WP Sayım uygulamasına kayıt başvurunuz onaylandı. Artık telefon numarası ve şifreniz ile giriş yapabilirsiniz."
      );

      // Uygulama içi bildirimi de kaydet
      await admin.firestore().collection("notifications").add({
        userId: event.params.userId,
        title: "Hesabınız Onaylandı!",
        body: "WP Sayım uygulamasına kayıt başvurunuz onaylandı. Artık giriş yapabilirsiniz.",
        type: "approval",
        relatedId: event.params.userId,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        isRead: false
      });
      console.log(`[sendApprovalNotification] Added in-app notification for ${event.params.userId}`);
    } else {
      // E-postası olmayan (normal push notification alan) kullanıcıya bildirim gönder
      console.log(`[sendApprovalNotification] No email found. Sending push notification for ${event.params.userId}`);
      await sendNotificationAndLog({
        userId: event.params.userId,
        title: "Hesabınız Onaylandı!",
        body: "WP Sayım uygulamasına kayıt başvurunuz onaylandı. Artık giriş yapabilirsiniz.",
        type: "approval",
        relatedId: event.params.userId,
        dataPayload: {
          type: "approval",
          userId: event.params.userId
        },
        tag: `approval_${event.params.userId}`,
        link: "https://lnyctophilia.github.io/WP_Sayim/"
      });
    }
  }
});

// 8. 30 Günden Eski, Bekleyen ve Reddedilen Davetleri Temizle (Ayın 1'inde ve 15'inde gece 04:00)
exports.cleanupOldDavetler = onSchedule({ schedule: "0 4 1,15 * *", timeZone: "Europe/Istanbul" }, async (event) => {
  const now = new Date();
  const thirtyDaysAgo = new Date(now.getTime() - (30 * 24 * 60 * 60 * 1000));
  
  const davetlerRef = admin.firestore().collection('davetler');
  
  const snapshot = await davetlerRef
    .where("createdAt", "<", admin.firestore.Timestamp.fromDate(thirtyDaysAgo))
    .get();

  if (snapshot.empty) {
    console.log("No old davetler found to delete.");
    return;
  }

  let batch = admin.firestore().batch();
  let count = 0;
  let totalDeleted = 0;

  for (const doc of snapshot.docs) {
    const data = doc.data();
    if (data.status === "pending" || data.status === "declined") {
      batch.delete(doc.ref);
      count++;
      totalDeleted++;

      if (count >= 400) {
        await batch.commit();
        batch = admin.firestore().batch();
        count = 0;
      }
    }
  }

  if (count > 0) {
    await batch.commit();
  }
  console.log(`cleanupOldDavetler finished. Deleted ${totalDeleted} pending/declined davetler older than 30 days.`);
});

// 9. 90 Günden Eski Sayımları ve İlişkili Verileri Temizle (Ayın 1'inde ve 15'inde gece 04:00)
exports.cleanupOldSayimlar = onSchedule({ schedule: "0 4 1,15 * *", timeZone: "Europe/Istanbul" }, async (event) => {
  const now = new Date();
  const ninetyDaysAgo = new Date(now.getTime() - (90 * 24 * 60 * 60 * 1000));
  
  const sayimlarRef = admin.firestore().collection('sayimlar');
  
  const snapshot = await sayimlarRef
    .where("date", "<", admin.firestore.Timestamp.fromDate(ninetyDaysAgo))
    .get();

  if (snapshot.empty) {
    console.log("No old sayimlar found to delete.");
    return;
  }

  let batch = admin.firestore().batch();
  let count = 0;
  let totalDeletedSayim = 0;

  for (const doc of snapshot.docs) {
    const sayimId = doc.id;
    const sayimData = doc.data();

    const davetlerSnap = await admin.firestore().collection("davetler")
      .where("sayimId", "==", sayimId)
      .get();

    for (const davetDoc of davetlerSnap.docs) {
      batch.delete(davetDoc.ref);
      count++;

      const davetData = davetDoc.data();
      if (davetData.status === "accepted" && sayimData.date) {
        const userId = davetData.userId;
        const dateObj = sayimData.date.toDate();
        
        const trtDateMs = dateObj.getTime() + (3 * 60 * 60 * 1000);
        const trtDateObj = new Date(trtDateMs);
        const year = trtDateObj.getUTCFullYear();
        const month = String(trtDateObj.getUTCMonth() + 1).padStart(2, '0');
        const day = String(trtDateObj.getUTCDate()).padStart(2, '0');
        const dateString = `${year}-${month}-${day}`;

        const workDayRef = admin.firestore()
          .collection('personel_takvimi')
          .doc(userId)
          .collection('gunler')
          .doc(dateString);
        
        batch.delete(workDayRef);
        count++;
      }

      if (count >= 400) {
        await batch.commit();
        batch = admin.firestore().batch();
        count = 0;
      }
    }

    batch.delete(doc.ref);
    count++;
    totalDeletedSayim++;

    if (count >= 400) {
      await batch.commit();
      batch = admin.firestore().batch();
      count = 0;
    }
  }

  if (count > 0) {
    await batch.commit();
  }
  
  console.log(`cleanupOldSayimlar finished. Deleted ${totalDeletedSayim} sayimlar (older than 90 days) and their related records.`);
});

// 10. 30 Günden Eski Bildirimleri Temizle (Ayın 1'inde ve 15'inde gece 04:00)
exports.cleanupOldNotifications = onSchedule({ schedule: "0 4 1,15 * *", timeZone: "Europe/Istanbul" }, async (event) => {
  const now = new Date();
  const thirtyDaysAgo = new Date(now.getTime() - (30 * 24 * 60 * 60 * 1000));
  
  const notifRef = admin.firestore().collection('notifications');
  
  const snapshot = await notifRef
    .where("createdAt", "<", admin.firestore.Timestamp.fromDate(thirtyDaysAgo))
    .get();

  if (snapshot.empty) {
    console.log("No old notifications found to delete.");
    return;
  }

  let batch = admin.firestore().batch();
  let count = 0;
  let totalDeleted = 0;

  for (const doc of snapshot.docs) {
    batch.delete(doc.ref);
    count++;
    totalDeleted++;

    if (count >= 400) {
      await batch.commit();
      batch = admin.firestore().batch();
      count = 0;
    }
  }

  if (count > 0) {
    await batch.commit();
  }
  console.log(`cleanupOldNotifications finished. Deleted ${totalDeleted} notifications older than 30 days.`);
});

// 11. Test Bildirimi Gönder (Kullanıcı ayarlardan test ettiğinde)
exports.sendTestNotification = onDocumentCreated("test_notifications/{docId}", async (event) => {
  console.log("sendTestNotification START! docId:", event.params.docId);
  const data = event.data.data();
  if (!data || !data.userId) {
    console.log("sendTestNotification: Missing data or userId, aborting.");
    return;
  }

  console.log("sendTestNotification: Waiting 10 seconds for user:", data.userId);
  // Wait 10 seconds so the user can put the app in the background to test push notifications
  await new Promise(resolve => setTimeout(resolve, 10000));

  console.log("sendTestNotification: Wait finished. Fetching user:", data.userId);
  const userDoc = await admin.firestore().collection("users").doc(data.userId).get();
  if (!userDoc.exists) {
    console.log("sendTestNotification: User doc does not exist:", data.userId);
    return;
  }

  const userData = userDoc.data();
  const hasEmail = userData.email && userData.email.trim() !== "";
  console.log("sendTestNotification: hasEmail?", hasEmail, "email:", userData.email);

  if (hasEmail) {
    console.log("sendTestNotification: Sending test email via EmailJS to:", userData.email);
    // E-postası olan kullanıcıya e-posta gönder (EmailJS üzerinden)
    await sendEmailJSEmail(
      userData.email,
      "WP Sayım - Bildirim Testi",
      "Bu bir test e-postasıdır. Eğer bu mesajı alıyorsanız, bildirim sisteminiz başarıyla çalışıyor demektir."
    );

    // Uygulama içi bildirimi de kaydet
    await admin.firestore().collection("notifications").add({
      userId: data.userId,
      title: "Test E-postası Gönderildi",
      body: "E-posta adresinize test maili gönderildi. Lütfen gelen kutunuzu kontrol edin.",
      type: "test",
      relatedId: event.params.docId,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      isRead: false
    });
    console.log("sendTestNotification: Added to 'notifications' collection.");
  } else {
    // E-postası olmayan kullanıcıya normal push notification gönder
    await sendNotificationAndLog({
      userId: data.userId,
      title: "Test Bildirimi",
      body: "Uygulama kapalıyken (veya arka plandayken) de bildirim alabiliyorsunuz. Harika!",
      type: "test",
      relatedId: event.params.docId,
      dataPayload: {
        type: "test"
      },
      tag: `test_${event.params.docId}`
    });
  }
});

// 12. iOS PWA Subscription Canlı Tutma (Keep-Alive)
// Her gün saat 04:00'te çalışır.
// Son 6 gündür push almamış, fcmToken'ı olan (email'i olmayan) kullanıcılara
// sessiz bir keep-alive push gönderir.
// iOS Safari, uzun süre push almayan PWA subscription'larını sessizce öldürür.
// Bu fonksiyon, subscription'ı canlı tutarak bildirimlerin kesilmesini önler.
exports.keepAliveSubscription = onSchedule({ schedule: "0 4 * * *", timeZone: "Europe/Istanbul" }, async (event) => {
  const now = Date.now();
  const sixDaysAgo = new Date(now - (6 * 24 * 60 * 60 * 1000));
  
  console.log("[KEEP-ALIVE] Başlatılıyor. 6 gündür push almamış kullanıcılar aranıyor...");
  
  const usersSnap = await admin.firestore().collection("users")
    .where("isApproved", "==", true)
    .where("active", "==", true)
    .get();
  
  if (usersSnap.empty) {
    console.log("[KEEP-ALIVE] Aktif kullanıcı bulunamadı.");
    return;
  }
  
  let sentCount = 0;
  let skippedCount = 0;
  let errorCount = 0;
  
  for (const userDoc of usersSnap.docs) {
    const userData = userDoc.data();
    const fcmToken = userData.fcmToken;
    const hasEmail = userData.email && userData.email.trim() !== "";
    const pushVersion = userData.pushVersion;
    
    // Email'i olan kullanıcılar push almıyor, skip
    // Ayrıca eski Service Worker sürümünde olanlara atma (pushVersion 2 değilse titrer!)
    if (!fcmToken || hasEmail || pushVersion !== 2) {
      skippedCount++;
      continue;
    }
    
    // Son push zamanını kontrol et
    const lastPush = userData.lastPushSentAt;
    
    // Eğer kullanıcı henüz hiç normal push almamışsa (alan yoksa), onu es geç.
    // Sadece daha önce push almış ama üzerinden 6 gün geçmiş kişileri hedefle.
    if (!lastPush) {
      skippedCount++;
      continue;
    }

    const lastPushDate = lastPush.toDate ? lastPush.toDate() : new Date(lastPush);
    if (lastPushDate > sixDaysAgo) {
      // Son 6 gün içinde push almış, keep-alive'a gerek yok, skip
      skippedCount++;
      continue;
    }
    
    // Buraya ulaştıysa: lastPushSentAt alanı var VE üzerinden 6 günden fazla geçmiş
    
    try {
      const message = {
        token: fcmToken,
        // notification alanı YOK — data-only push
        // Service Worker bu mesajı alıp sessiz bildirim gösterecek
        data: {
          type: "keep_alive",
          timestamp: String(now)
        },
        webpush: {
          headers: {
            Topic: "keep_alive",
            Urgency: "low",
            TTL: "86400" // 24 saat TTL
          }
        },
        android: {
          priority: "normal"
        },
        apns: {
          headers: {
            "apns-priority": "5", // Düşük öncelik
            "apns-collapse-id": "keep_alive"
          },
          payload: {
            aps: {
              "content-available": 1
            }
          }
        }
      };
      
      await admin.messaging().send(message);
      
      // Gönderim zamanını güncelle
      await admin.firestore().collection("users").doc(userDoc.id).update({
        lastPushSentAt: admin.firestore.FieldValue.serverTimestamp()
      });
      
      sentCount++;
      console.log(`[KEEP-ALIVE] Gönderildi: ${userDoc.id}`);
    } catch (e) {
      errorCount++;
      console.error(`[KEEP-ALIVE] Hata (${userDoc.id}):`, e.code || e.message);
      
      // Geçersiz token ise temizle
      const invalidTokenCodes = [
        'messaging/registration-token-not-registered',
        'messaging/invalid-registration-token',
        'messaging/third-party-auth-error',
        'messaging/mismatched-credential'
      ];
      
      if (e.code && invalidTokenCodes.includes(e.code)) {
        console.log(`[KEEP-ALIVE][TOKEN CLEANUP] Geçersiz token siliniyor: ${userDoc.id}`);
        try {
          await admin.firestore().collection("users").doc(userDoc.id).update({
            fcmToken: admin.firestore.FieldValue.delete(),
            fcmTokenInvalidatedAt: admin.firestore.FieldValue.serverTimestamp(),
            fcmTokenInvalidReason: e.code
          });
        } catch (cleanupErr) {
          console.error("[KEEP-ALIVE][TOKEN CLEANUP] Silme hatası:", cleanupErr);
        }
      }
    }
  }
  
  console.log(`[KEEP-ALIVE] Tamamlandı. Gönderilen: ${sentCount}, Atlanan: ${skippedCount}, Hata: ${errorCount}`);
});
