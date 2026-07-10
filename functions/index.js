const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");

admin.initializeApp();

exports.sendDavetNotification = onDocumentCreated("davetler/{davetId}", async (event) => {
  const davetData = event.data.data();
  if (!davetData) return;

  const staffId = davetData.staffId;
  const sayimName = davetData.sayimNote || "Yeni Sayım";
  
  if (!staffId) {
    console.log("No staffId in davet document.");
    return;
  }

  try {
    // Personelin user dokümanını çek
    const userDoc = await admin.firestore().collection("users").doc(staffId).get();
    
    if (!userDoc.exists) {
      console.log(`User ${staffId} not found.`);
      return;
    }

    const userData = userDoc.data();
    const fcmToken = userData.fcmToken;

    if (!fcmToken) {
      console.log(`User ${staffId} has no fcmToken.`);
      return;
    }

    // Push notification gönder (FCM)
    const message = {
      token: fcmToken,
      notification: {
        title: "Yeni Sayım Daveti",
        body: `Seni "${sayimName}" isimli sayıma davet ettiler. Lütfen uygulamaya girip onay ver.`
      },
      data: {
        type: "davet",
        davetId: event.params.davetId,
        sayimId: davetData.sayimId
      }
    };

    const response = await admin.messaging().send(message);
    console.log(`Successfully sent message to ${staffId}:`, response);
    
  } catch (error) {
    console.error("Error sending notification:", error);
  }
});
