const { onDocumentCreated, onDocumentUpdated, onDocumentDeleted } = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");

admin.initializeApp();

// 1. Yeni davet oluşturulduğunda personeli bilgilendir
exports.sendDavetNotification = onDocumentCreated("davetler/{davetId}", async (event) => {
  const davetData = event.data.data();
  if (!davetData) return;

  const staffId = davetData.userId;
  const sayimId = davetData.sayimId;
  
  if (!staffId) {
    console.log("No userId in davet document.");
    return;
  }

  try {
    // Sayım detayını çek
    const sayimDoc = await admin.firestore().collection("sayimlar").doc(sayimId).get();
    const sayimName = sayimDoc.exists ? (sayimDoc.data().note || "Yeni Sayım") : "Yeni Sayım";

    // Personelin user dokümanını çek
    const userDoc = await admin.firestore().collection("users").doc(staffId).get();
    
    if (!userDoc.exists) return;

    const fcmToken = userDoc.data().fcmToken;
    if (!fcmToken) return;

    const message = {
      token: fcmToken,
      notification: {
        title: "Yeni Sayım Daveti",
        body: `Seni "${sayimName}" isimli sayıma davet ettiler. Lütfen uygulamaya girip onay ver.`
      },
      data: {
        type: "davet",
        davetId: event.params.davetId,
        sayimId: sayimId
      }
    };

    await admin.messaging().send(message);
  } catch (error) {
    console.error("Error sending notification:", error);
  }
});

// 2. Davet durumu (kabul/red) değiştiğinde sayımı oluşturan kişiyi bilgilendir
exports.sendDavetResponseNotification = onDocumentUpdated("davetler/{davetId}", async (event) => {
  const oldData = event.data.before.data();
  const newData = event.data.after.data();

  if (!oldData || !newData) return;

  // Sadece status değiştiyse ve pending'den çıkmışsa
  if (oldData.status === newData.status) return;
  if (newData.status === "pending") return; // Geri alınma vs. durumları yoksay

  const staffId = newData.userId;
  const sayimId = newData.sayimId;
  const statusStr = newData.status === "accepted" ? "kabul etti" : "reddetti";

  try {
    // Sayım detayını çek
    const sayimDoc = await admin.firestore().collection("sayimlar").doc(sayimId).get();
    if (!sayimDoc.exists) return;
    const sayimData = sayimDoc.data();
    const sayimName = sayimData.note || "Bilinmeyen Sayım";
    const creatorId = sayimData.createdBy;

    // Eğer kendi davetini kabul ediyorsa (yöneticinin kendini eklemesi), bildirim gönderme
    if (staffId === creatorId) return;

    // Personelin adını al
    const staffDoc = await admin.firestore().collection("users").doc(staffId).get();
    const staffName = staffDoc.exists ? (staffDoc.data().fullName || "Bir personel") : "Bir personel";

    // Sayım oluşturucunun fcmToken'ını al
    const creatorDoc = await admin.firestore().collection("users").doc(creatorId).get();
    if (!creatorDoc.exists) return;
    const creatorFcmToken = creatorDoc.data().fcmToken;

    if (!creatorFcmToken) return;

    const message = {
      token: creatorFcmToken,
      notification: {
        title: "Davet Yanıtı",
        body: `${staffName}, "${sayimName}" sayım davetini ${statusStr}.`
      },
      data: {
        type: "davet_response",
        davetId: event.params.davetId,
        sayimId: sayimId
      }
    };

    await admin.messaging().send(message);
  } catch (error) {
    console.error("Error sending response notification:", error);
  }
});

// 3. Davet iptal edildiğinde (silindiğinde) personeli bilgilendir
exports.sendDavetCancelledNotification = onDocumentDeleted("davetler/{davetId}", async (event) => {
  const davetData = event.data.before.data();
  if (!davetData) return;

  // Sadece kabul etmiş personellere iptal bildirimi gönder
  if (davetData.status !== "accepted") return;

  const staffId = davetData.userId;
  const sayimId = davetData.sayimId;

  try {
    const sayimDoc = await admin.firestore().collection("sayimlar").doc(sayimId).get();
    const sayimName = sayimDoc.exists ? (sayimDoc.data().note || "Sayım") : "Sayım";

    const userDoc = await admin.firestore().collection("users").doc(staffId).get();
    if (!userDoc.exists) return;

    const fcmToken = userDoc.data().fcmToken;
    if (!fcmToken) return;

    const message = {
      token: fcmToken,
      notification: {
        title: "Sayım İptali",
        body: `Kabul ettiğiniz "${sayimName}" sayımı için katılımınız iptal edildi veya sayım silindi.`
      },
      data: {
        type: "davet_cancelled",
        sayimId: sayimId
      }
    };

    await admin.messaging().send(message);
  } catch (error) {
    console.error("Error sending cancellation notification:", error);
  }
});

// 4. Kullanıcı dokümanı (AppUser) güncellendiğinde Firebase Auth'u senkronize et
exports.syncUserWithAuth = onDocumentUpdated("users/{userId}", async (event) => {
  const oldData = event.data.before.data();
  const newData = event.data.after.data();

  if (!oldData || !newData) return;

  const updatePayload = {};

  // Şifre değişmişse
  if (oldData.password !== newData.password && newData.password) {
    updatePayload.password = newData.password;
  }

  // İsim değişmişse
  if (oldData.fullName !== newData.fullName) {
    updatePayload.displayName = newData.fullName;
  }

  if (Object.keys(updatePayload).length > 0) {
    try {
      await admin.auth().updateUser(event.params.userId, updatePayload);
      console.log(`Successfully synced auth for user: ${event.params.userId}`);
    } catch (error) {
      console.error(`Error syncing auth for user: ${event.params.userId}`, error);
    }
  }
});
