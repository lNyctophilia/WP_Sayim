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

// ─── SW AKTİVASYON GARANTİSİ ───
// Yeni versiyon deploy edildiğinde beklemeden aktif olması ve
// tüm açık sekmeleri (client'ları) hemen kontrol altına alması için:
self.addEventListener('install', function(event) {
  event.waitUntil(self.skipWaiting());
});
self.addEventListener('activate', function(event) {
  event.waitUntil(clients.claim());
});

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
    
    // ─── KEEP-ALIVE (SESSİZ) BİLDİRİM ───
    // Backend'den gelen periyodik canlı tutma push'u.
    // Sessiz bildirim göster → 3 saniye sonra otomatik kapat.
    // Kullanıcıyı rahatsız etmeden iOS subscription'ını canlı tutar.
    if (payload.data && payload.data.type === 'keep_alive') {
      console.log('[firebase-messaging-sw.js] Keep-alive push alındı. Geçici bildirim gösteriliyor...');
      
      const keepAlivePromise = self.registration.showNotification('Sistem Mesajı', {
        body: 'Bildirim sistemini canlı tutmak için geçici bildirim.',
        icon: '/icons/Icon-192.png',
        badge: '/icons/Icon-192.png',
        silent: true,           // Ses yok
        vibrate: [],            // Titreşim yok
        requireInteraction: false, // Otomatik kapanabilir
        tag: 'keep-alive',      // Aynı tag = üst üste binmez
        renotify: false,        // Yeniden bildirim sesi çalmaz
        data: { type: 'keep_alive' }
      }).then(function() {
        // 3 saniye sonra bildirimi sessizce kapat
        return new Promise(function(resolve) {
          setTimeout(function() {
            self.registration.getNotifications({ tag: 'keep-alive' }).then(function(notifications) {
              notifications.forEach(function(n) { n.close(); });
              console.log('[firebase-messaging-sw.js] Keep-alive bildirim kapatıldı.');
              resolve();
            });
          }, 3000);
        });
      });
      
      event.waitUntil(keepAlivePromise);
      
      // Token yenileme sinyali gönder
      notifyClientsToRefreshToken();
      return;
    }
    
    // ─── NORMAL BİLDİRİM ───
    const title = payload.notification?.title || payload.data?.title || 'WP Sayım';
    const body = payload.notification?.body || payload.data?.body || 'Yeni bir bildiriminiz var.';
    
    // iOS abonelik bug'ını aşmak için bildirimi gösterip promise'i döndürüyoruz.
    const promise = clients.matchAll({ type: 'window', includeUncontrolled: true }).then((windowClients) => {
      // Her push alındığında client'lara token yenileme sinyali gönder
      // iOS subscription'ının canlı kalmasını sağlar
      notifyClientsToRefreshToken();
      
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

// ─── iOS PUSH SUBSCRIPTION RENEWAL ────────────────────────────────
// iOS Safari, push subscription'ı sessizce yenileyebilir/geçersiz kılabilir.
// Bu event'i yakalayıp yeni subscription bilgisini client'a iletiyoruz,
// böylece Dart tarafı yeni FCM token'ı Firestore'a kaydedebilir.
self.addEventListener('pushsubscriptionchange', function(event) {
  console.log('[firebase-messaging-sw.js] pushsubscriptionchange tetiklendi!');
  console.log('[firebase-messaging-sw.js] Eski subscription:', event.oldSubscription);
  
  event.waitUntil(
    // Yeni subscription almayı dene
    self.registration.pushManager.subscribe(
      event.oldSubscription ? event.oldSubscription.options : { userVisibleOnly: true }
    ).then(function(newSubscription) {
      console.log('[firebase-messaging-sw.js] Yeni subscription alındı:', newSubscription.endpoint);
      
      // Açık olan tüm uygulama pencerelerine "token'ını yenile" mesajı gönder
      return clients.matchAll({ type: 'window', includeUncontrolled: true }).then(function(windowClients) {
        windowClients.forEach(function(client) {
          client.postMessage({
            type: 'SUBSCRIPTION_CHANGED',
            newEndpoint: newSubscription.endpoint
          });
        });
      });
    }).catch(function(err) {
      console.error('[firebase-messaging-sw.js] Yeni subscription alınamadı:', err);
      // Subscription tamamen öldüyse client'a haber ver, Dart tarafı resubscribe denesin
      return clients.matchAll({ type: 'window', includeUncontrolled: true }).then(function(windowClients) {
        windowClients.forEach(function(client) {
          client.postMessage({
            type: 'SUBSCRIPTION_EXPIRED'
          });
        });
      });
    })
  );
});

// ─── PUSH ALIMINDA TOKEN CANLI TUTMA ──────────────────────────────
// Her push alındığında, client'a "token'ını yenile" sinyali gönderiyoruz.
// Bu, iOS'un service worker'ı uzun süre uyutmasını engellemeye yardımcı olur
// ve token'ın her zaman güncel kalmasını sağlar.
function notifyClientsToRefreshToken() {
  clients.matchAll({ type: 'window', includeUncontrolled: true }).then(function(windowClients) {
    windowClients.forEach(function(client) {
      client.postMessage({ type: 'TOKEN_REFRESH_NEEDED' });
    });
  });
}

// Arka plan mesaj handler — uygulama kapalıyken gelen bildirimleri yakala
messaging.onBackgroundMessage(function(payload) {
  console.log('[firebase-messaging-sw.js] Arka plan bildirimi alındı:', payload);
  // Firebase, notification varsa zaten göstermeye çalışacak (fakat bizim deduplicator engelleyecek)
  // Biz zaten yukarıdaki 'push' dinleyicisinde iOS için garantili olarak gösterdik.
  
  // Token'ı taze tutmak için client'lara sinyal gönder
  notifyClientsToRefreshToken();
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
