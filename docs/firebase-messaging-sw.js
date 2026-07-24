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

// Firebase'in varsayılan davranışını (uygulama açıkken bildirimi göstermeme) aşmak için
// Kendi push dinleyicimizi ekliyoruz. Eğer uygulama aktifse (foreground), bildirimi ZORLA gösteriyoruz.
self.addEventListener('push', function(event) {
  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then((windowClients) => {
      let isFocused = false;
      for (let i = 0; i < windowClients.length; i++) {
        if (windowClients[i].focused) {
          isFocused = true;
          break;
        }
      }

      // Eğer uygulama ön planda (açık) ise Firebase bildirimi SESSİZE ALIR (gizler).
      // Chrome Android üzerinde main thread'den showNotification çağrısı bloklandığı için,
      // tek aşma yolu bunu Service Worker'ın 'push' event'inin tam kalbinde yapmaktır!
      if (isFocused && event.data) {
        try {
          const payload = event.data.json();
          const title = payload.notification?.title || payload.data?.title;
          const body = payload.notification?.body || payload.data?.body;
          
          if (title) {
            return self.registration.showNotification(title, {
              body: body,
              icon: '/icons/Icon-192.png',
              vibrate: [200, 100, 200],
              requireInteraction: true,
              tag: 'fg-notification-' + Date.now()
            });
          }
        } catch (e) {
          console.error('[firebase-messaging-sw.js] Foreground push parse hatası:', e);
        }
      }
    })
  );
});
// Arka plan mesaj handler — uygulama kapalıyken gelen bildirimleri yakala
messaging.onBackgroundMessage(function(payload) {
  console.log('[firebase-messaging-sw.js] Arka plan bildirimi alındı:', payload);

  // Firebase, eğer payload içinde 'notification' objesi varsa (ki Cloud Functions'ta var) 
  // arka planda varsayılan olarak zaten bir bildirim gösterir!
  // Biz de burada tekrar showNotification çağırırsak ÇİFT bildirim gider.
  // Bu yüzden, eğer notification varsa işlemi Firebase'e bırakıyoruz.
  if (payload.notification) {
    console.log('[firebase-messaging-sw.js] Bildirim zaten Firebase tarafından gösterilecek, atlanıyor.');
    return;
  }

  // Sadece "data" mesajı gelirse özel bildirim göster (Gelecekte gerekirse diye kalsın)
  const notificationTitle = payload.data?.title || 'WP Sayım';
  const notificationOptions = {
    body: payload.data?.body || 'Yeni bir bildiriminiz var.',
    icon: '/icons/Icon-192.png',
    badge: '/icons/Icon-192.png',
    data: payload.data,
    tag: payload.data?.type || 'default',
    renotify: true,
  };

  return self.registration.showNotification(notificationTitle, notificationOptions);
});

// Bildirime tıklanınca uygulamayı aç
self.addEventListener('notificationclick', function(event) {
  console.log('[firebase-messaging-sw.js] Bildirime tıklandı:', event);
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
