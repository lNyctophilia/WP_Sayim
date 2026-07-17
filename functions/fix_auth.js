const admin = require("firebase-admin");
admin.initializeApp();

async function fixDeletedUsers() {
  try {
    const usersSnap = await admin.firestore().collection("users").where("isDeleted", "==", true).get();
    
    if (usersSnap.empty) {
      console.log("Silinmiş (isDeleted: true) kullanıcı bulunamadı.");
      return;
    }

    console.log(`Toplam ${usersSnap.size} adet silinmiş kullanıcı bulundu. Auth hesapları güncelleniyor...`);

    let updatedCount = 0;
    for (const doc of usersSnap.docs) {
      const data = doc.data();
      if (!data.username) continue;
      
      const newEmail = `${data.username.trim().toLowerCase()}@wpsayim.local`;
      
      try {
        await admin.auth().updateUser(doc.id, { email: newEmail });
        console.log(`Güncellendi: ${doc.id} -> ${newEmail}`);
        updatedCount++;
      } catch (err) {
        if (err.code === "auth/user-not-found") {
          console.log(`Kullanıcı zaten Auth'tan silinmiş: ${doc.id}`);
        } else {
          console.error(`Hata (${doc.id}):`, err);
        }
      }
    }
    console.log(`İşlem tamamlandı. ${updatedCount} kullanıcının email'i değiştirildi.`);
  } catch (error) {
    console.error("Genel hata:", error);
  } finally {
    process.exit(0);
  }
}

fixDeletedUsers();
