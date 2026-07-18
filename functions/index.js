const { onDocumentCreated, onDocumentUpdated, onDocumentDeleted } = require("firebase-functions/v2/firestore");
const { onSchedule } = require("firebase-functions/v2/scheduler");
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
    if (!sayimDoc.exists) return;

    const sayimData = sayimDoc.data();
    const sayimName = sayimData.note || "Yeni Sayım";
    const creatorId = sayimData.createdBy;

    // Eğer sayımı oluşturan kişi kendini sayıma eklediyse (otomatik onaylanır), bildirim gönderme
    if (staffId === creatorId) {
      console.log(`Davet notification skipped: Creator ${creatorId} added themselves.`);
      return;
    }

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
      android: {
        priority: "high",
        notification: {
          channelId: "sayim_notifications",
          tag: `davet_${event.params.davetId}`
        }
      },
      webpush: {
        headers: {
          Topic: `davet_${event.params.davetId}`
        },
        fcmOptions: {
          link: "https://lnyctophilia.github.io/WP_Sayim/?open_notifications=true"
        }
      },
      apns: {
        headers: {
          "apns-collapse-id": `davet_${event.params.davetId}`
        }
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
      android: {
        priority: "high",
        notification: {
          channelId: "sayim_notifications",
          tag: `davet_response_${event.params.davetId}`
        }
      },
      webpush: {
        headers: {
          Topic: `davet_response_${event.params.davetId}`
        },
        fcmOptions: {
          link: "https://lnyctophilia.github.io/WP_Sayim/?open_notifications=true"
        }
      },
      apns: {
        headers: {
          "apns-collapse-id": `davet_response_${event.params.davetId}`
        }
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

// 2.5 Davete hatırlatma gönderildiğinde personeli bilgilendir
exports.sendDavetReminderNotification = onDocumentUpdated("davetler/{davetId}", async (event) => {
  const oldData = event.data.before.data();
  const newData = event.data.after.data();

  if (!oldData || !newData) return;

  // Sadece lastReminderAt değişmişse
  const oldReminder = oldData.lastReminderAt ? oldData.lastReminderAt.toMillis() : null;
  const newReminder = newData.lastReminderAt ? newData.lastReminderAt.toMillis() : null;

  if (!newReminder || oldReminder === newReminder) return;

  const staffId = newData.userId;
  const sayimId = newData.sayimId;

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
        title: "Yeni Sayım Daveti",
        body: `Seni "${sayimName}" isimli sayıma davet ettiler. Lütfen uygulamaya girip onay ver.`
      },
      android: {
        priority: "high",
        notification: {
          channelId: "sayim_notifications",
          tag: `davet_${event.params.davetId}`
        }
      },
      webpush: {
        headers: {
          Topic: `davet_${event.params.davetId}`
        },
        fcmOptions: {
          link: "https://lnyctophilia.github.io/WP_Sayim/?open_notifications=true"
        }
      },
      apns: {
        headers: {
          "apns-collapse-id": `davet_${event.params.davetId}`
        }
      },
      data: {
        type: "davet",
        davetId: event.params.davetId,
        sayimId: sayimId
      }
    };

    await admin.messaging().send(message);
  } catch (error) {
    console.error("Error sending reminder notification:", error);
  }
});

// 3. Davet iptal edildiğinde (silindiğinde) personeli bilgilendir
exports.sendDavetCancelledNotification = onDocumentDeleted("davetler/{davetId}", async (event) => {
  const davetData = event.data.data();
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
        body: `Kabul ettiğin "${sayimName}" isimli sayım iptal edildi.`
      },
      android: {
        priority: "high",
        notification: {
          channelId: "sayim_notifications",
          tag: `davet_${event.params.davetId}`
        }
      },
      webpush: {
        headers: {
          Topic: `davet_${event.params.davetId}`
        },
        fcmOptions: {
          link: "https://lnyctophilia.github.io/WP_Sayim/?open_notifications=true"
        }
      },
      apns: {
        headers: {
          "apns-collapse-id": `davet_${event.params.davetId}`
        }
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

  // Şifre alanı varsa (yeni atanmış veya eskiden kalmış olabilir), auth'u güncelle ve ardından sil
  if (newData.password) {
    updatePayload.password = newData.password;
  }

  // İsim değişmişse
  if (oldData.fullName !== newData.fullName) {
    updatePayload.displayName = newData.fullName;
  }

  // Kullanıcı adı değişmişse (Özellikle soft delete durumlarında)
  if (oldData.username !== newData.username && newData.username) {
    updatePayload.email = `${newData.username.trim().toLowerCase()}@wpsayim.local`;
  }

  if (Object.keys(updatePayload).length > 0) {
    try {
      await admin.auth().updateUser(event.params.userId, updatePayload);
      console.log(`Successfully synced auth for user: ${event.params.userId}`);
      
      // Şifre güncellendiyse, Firestore'dan güvenlik için sil
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
  
  // Sadece açık sayımları getir
  const sayimlarSnap = await admin.firestore().collection("sayimlar")
    .where("status", "==", "open")
    .get();

  if (sayimlarSnap.empty) return;

  for (const sayimDoc of sayimlarSnap.docs) {
    const sayimData = sayimDoc.data();
    if (!sayimData || !sayimData.date || !sayimData.gruplar) continue;
    
    // Sadece bu sayımın kabul edilmiş davetlerini getir
    const davetlerSnap = await admin.firestore().collection("davetler")
      .where("sayimId", "==", sayimDoc.id)
      .where("status", "==", "accepted")
      .get();

    if (davetlerSnap.empty) continue;

    for (const davetDoc of davetlerSnap.docs) {
      const davet = davetDoc.data();
      
      // Daha önce bu otomatik bildirim atıldıysa geç
      if (davet.autoReminderSent === true) continue;

      // Kullanıcının grup saatini bul
      const grup = sayimData.gruplar.find(g => g.grupId === davet.grupId);
      if (!grup || !grup.saat) continue;

      // Sayım tarihini Türkiye saatiyle (UTC+3) çöz ki gün kayması olmasın
      const sayimDateObj = sayimData.date.toDate();
      const trtDateMs = sayimDateObj.getTime() + (3 * 60 * 60 * 1000); // TRT'ye göre günü belirle
      const trtDateObj = new Date(trtDateMs);
      
      const year = trtDateObj.getUTCFullYear();
      const month = String(trtDateObj.getUTCMonth() + 1).padStart(2, '0');
      const day = String(trtDateObj.getUTCDate()).padStart(2, '0');
      
      // Grup saati örn: "03:30", "16:00"
      // İkisini birleştirip ISO formatında (Türkiye Saati +03:00 ile) kesin zaman yarat
      const isoString = `${year}-${month}-${day}T${grup.saat}:00+03:00`;
      const finalSayimDate = new Date(isoString);

      // Şu anki zamana göre kaç saat kalmış hesapla
      const diffHours = (finalSayimDate.getTime() - nowMs) / (1000 * 60 * 60);

      console.log(`[Reminder Debug] Sayım ID: ${sayimDoc.id}, Davet ID: ${davetDoc.id}`);
      console.log(`[Reminder Debug] Sayım Zamanı: ${isoString}, Kalan Saat: ${diffHours}`);

      // Sayımın başlamasına 0 ile 3 saat arası kalmışsa tetikle
      if (diffHours > 0 && diffHours <= 3) {
        // Kullanıcının hatırlatıcı ayarını kontrol et
        const userDoc = await admin.firestore().collection("users").doc(davet.userId).get();
        if (!userDoc.exists) continue;
        
        const userData = userDoc.data();
        if (userData.sayimReminderEnabled === false) continue; // Kullanıcı ayarlarından kapatmışsa atlama

        const fcmToken = userData.fcmToken;
        if (fcmToken) {
          const sayimName = sayimData.note || "Sayım";
          const message = {
            token: fcmToken,
            notification: {
              title: "Yaklaşan Sayım",
              body: `Bugün saat ${grup.saat}'te "${sayimName}" sayımı var. Lütfen vaktinde orada olun.`
            },
            android: {
              priority: "high",
              notification: {
                channelId: "sayim_notifications",
                tag: `sayim_auto_reminder_${davetDoc.id}`
              }
            },
            webpush: {
              headers: {
                Topic: `sayim_auto_reminder_${davetDoc.id}`
              },
              fcmOptions: {
                link: "https://lnyctophilia.github.io/WP_Sayim/?open_notifications=true"
              }
            },
            apns: {
              headers: {
                "apns-collapse-id": `sayim_auto_reminder_${davetDoc.id}`
              }
            },
            data: {
              type: "sayim_auto_reminder",
              davetId: davetDoc.id,
              sayimId: sayimDoc.id
            }
          };

          try {
            await admin.messaging().send(message);
            // Bildirimin atıldığını kaydet ki bir sonraki döngüde tekrar atmasın
            await davetDoc.ref.update({ autoReminderSent: true });
          } catch (e) {
            console.error("Error sending scheduled reminder for davet " + davetDoc.id, e);
          }
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

  // Check if isApproved changed from false to true
  if (oldData.isApproved === false && newData.isApproved === true) {
    const fcmToken = newData.fcmToken;
    if (!fcmToken) return;

    const message = {
      token: fcmToken,
      notification: {
        title: "Hesabınız Onaylandı!",
        body: "WP Sayım uygulamasına kayıt başvurunuz onaylandı. Artık giriş yapabilirsiniz."
      },
      android: {
        priority: "high",
        notification: {
          channelId: "sayim_notifications",
          tag: `approval_${event.params.userId}`
        }
      },
      webpush: {
        headers: {
          Topic: `approval_${event.params.userId}`
        },
        fcmOptions: {
          link: "https://lnyctophilia.github.io/WP_Sayim/"
        }
      },
      apns: {
        headers: {
          "apns-collapse-id": `approval_${event.params.userId}`
        }
      },
      data: {
        type: "approval",
        userId: event.params.userId
      }
    };

    try {
      await admin.messaging().send(message);
      console.log(`Approval notification sent to user: ${event.params.userId}`);
    } catch (error) {
      console.error(`Error sending approval notification to user: ${event.params.userId}`, error);
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
    // Sadece beklemede olan veya reddedilmiş davetleri sil
    if (data.status === "pending" || data.status === "declined") {
      batch.delete(doc.ref);
      count++;
      totalDeleted++;

      // Firestore toplu işlem limiti (500), güvenli olması için 400'de bir commit et
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

    // 1. Davetleri ve takvimleri sil
    const davetlerSnap = await admin.firestore().collection("davetler")
      .where("sayimId", "==", sayimId)
      .get();

    for (const davetDoc of davetlerSnap.docs) {
      // Daveti sil
      batch.delete(davetDoc.ref);
      count++;

      // Davet kabul edilmişse çalışanın iş takviminden de sil
      const davetData = davetDoc.data();
      if (davetData.status === "accepted" && sayimData.date) {
        const userId = davetData.userId;
        const dateObj = sayimData.date.toDate();
        
        // Türkiye saati bazında (UTC+3) tarihi çözümleyip YYYY-MM-DD formatını elde et
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

    // 2. Sayımın kendisini sil
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
