// Firebase Messaging Service Worker — Arka planda bildirim dinleyicisi
// Bu dosya, uygulama kapalıyken bile bildirimleri yakalar ve gösterir.

importScripts("https://www.gstatic.com/firebasejs/10.13.2/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.13.2/firebase-messaging-compat.js");

firebase.initializeApp({
  apiKey: "AIzaSyBxQrbpgkVPWkou0HiMGGf_cpQ5UK29LQU",
  authDomain: "wp-sayim.firebaseapp.com",
  projectId: "wp-sayim",
  storageBucket: "wp-sayim.firebasestorage.app",
  messagingSenderId: "224740813185",
  appId: "1:224740813185:web:7e8779ae1b54a22c2c6080",
});

const messaging = firebase.messaging();

// ÇİFT BİLDİRİM ENGELLEYİCİ (Deduplicator)
// Biz kendi 'push' event'imizde iOS'i memnun etmek için her zaman bildirim gösteriyoruz.
// Ancak Firebase de arka plandayken kendi bildirimini göstermeye çalışır.
// Bu çakışmayı önlemek için Service Worker'ın bildirim gösterme fonksiyonunu araya girerek eziyoruz.
let lastPushTime = 0;
let lastPushTitle = "";
const originalShowNotification = self.registration.showNotification.bind(self.registration);
self.registration.showNotification = function(title, options) {
  const now = Date.now();
  // Son 2 saniye içinde aynı başlıkla bir bildirim gösterildiyse, diğerini (Firebase'inkini) yoksay.
  if (now - lastPushTime < 2000 && lastPushTitle === title) {
    console.log('[firebase-messaging-sw.js] Çift bildirim engellendi:', title);
    return Promise.resolve();
  }
  lastPushTime = now;
  lastPushTitle = title;
  return originalShowNotification(title, options);
};

// iOS'in aboneliği öldürmemesi için, push event'inde her durumda (foreground/background)
// event.waitUntil() içinde showNotification çağrılmak ZORUNDADIR.
self.addEventListener('push', function(event) {
  if (!event.data) return;

  try {
    const payload = event.data.json();
    const title = payload.notification?.title || payload.data?.title || 'WP Sayım';
    const body = payload.notification?.body || payload.data?.body || 'Yeni bir bildiriminiz var.';
    
    // iOS abonelik bug'ını aşmak için bildirimi gösterip promise'i döndürüyoruz.
    const promise = clients.matchAll({ type: 'window', includeUncontrolled: true }).then((windowClients) => {
      return self.registration.showNotification(title, {
        body: body,
        icon: '/icons/Icon-192.png',
        badge: '/icons/Icon-192.png',
        vibrate: [200, 100, 200],
        requireInteraction: true,
        tag: 'wp-notification-' + Date.now(), // Unique tag
        data: payload.data
      });
    });

    event.waitUntil(promise);
  } catch (e) {
    console.error('[firebase-messaging-sw.js] Push parse hatası:', e);
  }
});

// Arka plan mesaj handler — uygulama kapalıyken gelen bildirimleri yakala
messaging.onBackgroundMessage(function(payload) {
  console.log('[firebase-messaging-sw.js] Arka plan bildirimi alındı:', payload);
  // Firebase, notification varsa zaten göstermeye çalışacak (fakat bizim deduplicator engelleyecek)
  // Biz zaten yukarıdaki 'push' dinleyicisinde iOS için garantili olarak gösterdik.
  return;
});

// Bildirime tıklanınca uygulamayı aç
self.addEventListener('notificationclick', function(event) {
  console.log('[firebase-messaging-sw.js] Bildirime tıklandı:', event);
  
  // iOS için kritik: Yönlendirme sorunlarını önler
  event.preventDefault();
  event.notification.close();

  // Uygulama zaten açıksa onu odakla, değilse yeni pencere aç
  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then(function(clientList) {
      for (const client of clientList) {
        if (client.url.includes('/WP_Sayim') && 'focus' in client) {
          return client.focus();
        }
      }
      // Eğer uygulama arka planda hiç açık değilse, sıfırdan başlat
      return clients.openWindow('/WP_Sayim/');
    })
  );
});
