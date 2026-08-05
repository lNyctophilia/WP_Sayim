const admin = require("firebase-admin");

admin.initializeApp({
  projectId: "wp-sayim"
});

async function run() {
  console.log("Checking test_notifications...");
  const tests = await admin.firestore().collection("test_notifications")
    .orderBy("createdAt", "desc")
    .limit(5)
    .get();
    
  tests.forEach(doc => {
    console.log("Test doc:", doc.id, doc.data());
  });

  console.log("Checking mail...");
  const mails = await admin.firestore().collection("mail")
    .orderBy("message.subject")
    .limit(5)
    .get();
    
  mails.forEach(doc => {
    console.log("Mail doc:", doc.id, doc.data());
  });
}

run().catch(console.error);
