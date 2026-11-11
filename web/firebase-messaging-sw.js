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

// VAPID public key — pushsubscriptionchange handler'ında yeniden abone olmak için gerekli.
const VAPID_PUBLIC_KEY = 'BOkvHMWfKFEaXrwF-TgJ9KrrJSnNqL3tO966nz5F-esnB6SYZCfSIy6uWe9dvVTKfhPsTZ771DOsGVJY4JeDmio';

// Cloudflare Worker URL ve SW → Worker shared secret
// Bu secret, Cloudflare Worker'daki SW_UPDATE_SECRET env değişkeni ile aynı olmalı.
const CF_WORKER_URL = 'https://wp-sayim-api.nycgamedevs.workers.dev';
const SW_UPDATE_SECRET = 'dc94a8516b8ccc9c0f10daddb4e04e7043c3a1f239384f5298dfab5c06168b28';

const messaging = firebase.messaging();

// ─── IndexedDB YARDIMCILARI ─────────────────────────────────────────────────
// Kullanıcının Firebase UID'sini SW kapansa da kalıcı olarak saklamak için.
function _swDbOpen() {
  return new Promise((resolve, reject) => {
    const req = indexedDB.open('wp-sayim-sw-config', 1);
    req.onupgradeneeded = (e) => {
      e.target.result.createObjectStore('config');
    };
    req.onsuccess = (e) => resolve(e.target.result);
    req.onerror = (e) => reject(e.target.error);
  });
}

async function swDbGet(key) {
  try {
    const db = await _swDbOpen();
    return new Promise((resolve, reject) => {
      const tx = db.transaction('config', 'readonly');
      const req = tx.objectStore('config').get(key);
      req.onsuccess = (e) => resolve(e.target.result ?? null);
      req.onerror = (e) => reject(e.target.error);
    });
  } catch (e) { return null; }
}

async function swDbSet(key, value) {
  try {
    const db = await _swDbOpen();
    return new Promise((resolve, reject) => {
      const tx = db.transaction('config', 'readwrite');
      tx.objectStore('config').put(value, key);
      tx.oncomplete = () => resolve();
      tx.onerror = (e) => reject(e.target.error);
    });
  } catch (e) { /* sessiz hata */ }
}

// ─── SW AKTİVASYON GARANTİSİ ───────────────────────────────────────────────
self.addEventListener('install', function(event) {
  event.waitUntil(self.skipWaiting());
});

self.addEventListener('activate', function(event) {
  event.waitUntil(
    clients.claim().then(function() {
      // Proaktif subscription kontrolü: SW aktive olduğunda subscription hâlâ canlı mı?
      return self.registration.pushManager.getSubscription().then(function(subscription) {
        if (!subscription) {
          console.log('[SW] Activate: Subscription yok! Token yenileme sinyali gönderiliyor...');
          notifyClientsToRefreshToken();
        }
      }).catch(function() {});
    })
  );
});

// ─── MAIN THREAD'DEN MESAJ DİNLEYİCİ ───────────────────────────────────────
// Flutter app, giriş yapıldığında userId'yi SW'ye gönderir.
// SW bunu IndexedDB'de saklar — uygulama kapalıyken de kullanabilmek için.
self.addEventListener('message', function(event) {
  if (!event.data || !event.data.type) return;

  if (event.data.type === 'SET_USER_ID') {
    const userId = event.data.userId;
    if (userId) {
      swDbSet('userId', userId).then(() => {
        console.log('[SW] UserId IndexedDB\'e kaydedildi:', userId);
      });
    }
  }

  if (event.data.type === 'CLEAR_USER_ID') {
    swDbSet('userId', null).then(() => {
      console.log('[SW] UserId temizlendi (çıkış yapıldı).');
    });
  }
});

// ─── ÇİFT BİLDİRİM ENGELLEYİCİ (Safety Net) ───────────────────────────────
// Data-only payload kullanıldığında FCM SDK otomatik bildirim göstermez,
// bu yüzden çift bildirim normalde oluşmaz. Yine de güvenlik için korunuyor.
let lastPushTime = 0;
let lastPushTitle = "";
const originalShowNotification = self.registration.showNotification.bind(self.registration);
self.registration.showNotification = function(title, options) {
  const now = Date.now();
  if (now - lastPushTime < 2000 && lastPushTitle === title) {
    console.log('[SW] Çift bildirim engellendi:', title);
    return Promise.resolve();
  }
  lastPushTime = now;
  lastPushTitle = title;
  return originalShowNotification(title, options);
};

// ─── PUSH EVENT ─────────────────────────────────────────────────────────────
// iOS'un aboneliği öldürmemesi için showNotification ZORUNLU.
self.addEventListener('push', function(event) {
  if (!event.data) {
    event.waitUntil(
      self.registration.showNotification('WP Sayım', {
        body: 'Yeni bir bildiriminiz var.',
        icon: '/icons/Icon-192.png',
        badge: '/icons/Icon-192.png',
      })
    );
    return;
  }

  let title = 'WP Sayım';
  let body = 'Yeni bir bildiriminiz var.';
  let notifData = {};

  try {
    const payload = event.data.json();
    // Data-only payload: title/body artık data içinde geliyor.
    // Backward compat: notification alanı da kontrol ediliyor.
    title = payload.data?.title || payload.notification?.title || title;
    body = payload.data?.body || payload.notification?.body || body;
    notifData = payload.data || {};
  } catch (e) {
    console.error('[SW] Push parse hatası:', e);
  }

  const promise = clients.matchAll({ type: 'window', includeUncontrolled: true }).then((windowClients) => {
    notifyClientsToRefreshToken();
    return self.registration.showNotification(title, {
      body: body,
      icon: '/icons/Icon-192.png',
      badge: '/icons/Icon-192.png',
      vibrate: [200, 100, 200],
      requireInteraction: true,
      tag: 'wp-notification-' + Date.now(),
      data: notifData,
    });
  });

  event.waitUntil(promise);
});

// ─── iOS / ANDROID PUSH SUBSCRIPTION DEĞİŞİKLİĞİ ──────────────────────────
// Subscription değişince (Chrome/Safari sessiz yenileme), önce token'ı
// doğrudan Cloudflare Worker üzerinden Firestore'a yazar.
// Uygulama kapalı olsa bile çalışır — ghost bildirim göndermez.
self.addEventListener('pushsubscriptionchange', function(event) {
  console.log('[SW] pushsubscriptionchange tetiklendi!');

  function urlBase64ToUint8Array(base64String) {
    const padding = '='.repeat((4 - base64String.length % 4) % 4);
    const base64 = (base64String + padding).replace(/-/g, '+').replace(/_/g, '/');
    const rawData = atob(base64);
    return Uint8Array.from([...rawData].map(char => char.charCodeAt(0)));
  }

  const applicationServerKey = urlBase64ToUint8Array(VAPID_PUBLIC_KEY);

  const updatePromise = self.registration.pushManager.subscribe({
    userVisibleOnly: true,
    applicationServerKey: applicationServerKey,
  }).then(async function(newSubscription) {
    console.log('[SW] Yeni subscription alındı:', newSubscription.endpoint);

    // ── FCM token al ve Cloudflare üzerinden Firestore'a yaz ──────────────
    // Uygulama açık olmasa da çalışır.
    try {
      const newToken = await messaging.getToken({
        vapidKey: VAPID_PUBLIC_KEY,
        serviceWorkerRegistration: self.registration,
      });

      if (newToken) {
        const userId = await swDbGet('userId');

        if (userId) {
          // Cloudflare Worker'a direkt yaz — Flutter app'e gerek yok
          const res = await fetch(`${CF_WORKER_URL}/api/sw/update-token`, {
            method: 'POST',
            headers: {
              'Content-Type': 'application/json',
              'X-SW-Secret': SW_UPDATE_SECRET,
            },
            body: JSON.stringify({ userId, fcmToken: newToken }),
          });
          if (res.ok) {
            console.log('[SW] Token Cloudflare üzerinden Firestore\'a yazıldı. userId:', userId);
          } else {
            console.error('[SW] Cloudflare token güncelleme başarısız:', res.status);
          }
        } else {
          // userId yoksa client'lara bildir — app açılınca halleder
          console.log('[SW] userId yok, client\'lara bildirim gönderiliyor...');
          notifyClientsWithReason('SUBSCRIPTION_CHANGED');
        }
      }
    } catch (tokenErr) {
      console.error('[SW] getToken hatası:', tokenErr);
      // getToken başarısız → client'lara bildir
      notifyClientsWithReason('SUBSCRIPTION_CHANGED');
    }

  }).catch(function(err) {
    console.error('[SW] Yeni subscription alınamadı:', err);
    notifyClientsWithReason('SUBSCRIPTION_EXPIRED');
  });

  event.waitUntil(updatePromise);
});

// ─── CLIENT BİLDİRİM YARDIMCIları ──────────────────────────────────────────
function notifyClientsToRefreshToken() {
  clients.matchAll({ type: 'window', includeUncontrolled: true }).then(function(windowClients) {
    windowClients.forEach(function(client) {
      client.postMessage({ type: 'TOKEN_REFRESH_NEEDED' });
    });
  });
}

function notifyClientsWithReason(reason) {
  clients.matchAll({ type: 'window', includeUncontrolled: true }).then(function(windowClients) {
    windowClients.forEach(function(client) {
      client.postMessage({ type: reason });
    });
  });
}

// ─── BİLDİRİME TIKLAMA ─────────────────────────────────────────────────────
self.addEventListener('notificationclick', function(event) {
  console.log('[SW] Bildirime tıklandı:', event);
  event.preventDefault();
  event.notification.close();

  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then(function(clientList) {
      for (const client of clientList) {
        if (client.url.includes('/WP_Sayim') && 'focus' in client) {
          return client.focus();
        }
      }
      return clients.openWindow('/WP_Sayim/');
    })
  );
});

// ─── SW AKTİVASYON GARANTİSİ ───
// Yeni versiyon deploy edildiğinde beklemeden aktif olması ve
// tüm açık sekmeleri (client'ları) hemen kontrol altına alması için:
self.addEventListener('install', function(event) {
  event.waitUntil(self.skipWaiting());
});
self.addEventListener('activate', function(event) {
  event.waitUntil(
    clients.claim().then(function() {
      // Proaktif subscription kontrolü: SW aktive olduğunda subscription hâlâ canlı mı?
      // iOS Safari PWA'da subscription sessizce ölebilir — erken tespit et.
      return self.registration.pushManager.getSubscription().then(function(subscription) {
        if (!subscription) {
          console.log('[firebase-messaging-sw.js] Activate: Subscription yok! Client\'lara token yenileme sinyali gönderiliyor...');
          notifyClientsToRefreshToken();
        }
      }).catch(function() {});
    })
  );
});

// ÇİFT BİLDİRİM ENGELLEYİCİ (Deduplicator — Safety Net)
// Data-only payload kullanıldığında FCM SDK otomatik bildirim göstermez,
// bu yüzden çift bildirim normalde oluşmaz. Yine de güvenlik için korunuyor.
let lastPushTime = 0;
let lastPushTitle = "";
const originalShowNotification = self.registration.showNotification.bind(self.registration);
self.registration.showNotification = function(title, options) {
  const now = Date.now();
  if (now - lastPushTime < 2000 && lastPushTitle === title) {
    console.log('[firebase-messaging-sw.js] Çift bildirim engellendi:', title);
    return Promise.resolve();
  }
  lastPushTime = now;
  lastPushTitle = title;
  return originalShowNotification(title, options);
};

// iOS'un aboneliği öldürmemesi için, push event'inde her durumda (foreground/background)
// event.waitUntil() içinde showNotification çağrılmak ZORUNDADIR.
self.addEventListener('push', function(event) {
  if (!event.data) {
    // iOS: data gelse de gelmese de showNotification çağrılmalı (budget ihlali olmasın)
    event.waitUntil(
      self.registration.showNotification('WP Sayım', {
        body: 'Yeni bir bildiriminiz var.',
        icon: '/icons/Icon-192.png',
        badge: '/icons/Icon-192.png',
      })
    );
    return;
  }

  let title = 'WP Sayım';
  let body = 'Yeni bir bildiriminiz var.';
  let notifData = {};

  try {
    const payload = event.data.json();
    // Data-only payload: title ve body artık data içinde geliyor (Cloudflare Worker değişikliği).
    // Backward compat: notification alanı da kontrol ediliyor (eski mesajlar için).
    title = payload.data?.title || payload.notification?.title || title;
    body = payload.data?.body || payload.notification?.body || body;
    notifData = payload.data || {};
  } catch (e) {
    // JSON parse başarısız — fallback değerleri kullan (iOS budget koruması için yine de göster)
    console.error('[firebase-messaging-sw.js] Push parse hatası:', e);
  }

  const promise = clients.matchAll({ type: 'window', includeUncontrolled: true }).then((windowClients) => {
    // Her push alındığında client'lara token yenileme sinyali gönder
    notifyClientsToRefreshToken();

    return self.registration.showNotification(title, {
      body: body,
      icon: '/icons/Icon-192.png',
      badge: '/icons/Icon-192.png',
      vibrate: [200, 100, 200],
      requireInteraction: true,
      tag: 'wp-notification-' + Date.now(), // Unique tag
      data: notifData
    });
  });

  event.waitUntil(promise);
});

// ─── iOS PUSH SUBSCRIPTION RENEWAL ────────────────────────────────
// iOS Safari, push subscription'ı sessizce yenileyebilir/geçersiz kılabilir.
// Bu event'i yakalayıp yeni subscription bilgisini client'a iletiyoruz,
// böylece Dart tarafı yeni FCM token'ı Firestore'a kaydedebilir.
self.addEventListener('pushsubscriptionchange', function(event) {
  console.log('[firebase-messaging-sw.js] pushsubscriptionchange tetiklendi!');

  // VAPID key'i base64url → Uint8Array'e çevir
  function urlBase64ToUint8Array(base64String) {
    const padding = '='.repeat((4 - base64String.length % 4) % 4);
    const base64 = (base64String + padding).replace(/-/g, '+').replace(/_/g, '/');
    const rawData = atob(base64);
    return Uint8Array.from([...rawData].map(char => char.charCodeAt(0)));
  }

  const applicationServerKey = urlBase64ToUint8Array(VAPID_PUBLIC_KEY);

  event.waitUntil(
    self.registration.pushManager.subscribe({
      userVisibleOnly: true,
      applicationServerKey: applicationServerKey
    }).then(function(newSubscription) {
      console.log('[firebase-messaging-sw.js] Yeni subscription alındı:', newSubscription.endpoint);
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
      return clients.matchAll({ type: 'window', includeUncontrolled: true }).then(function(windowClients) {
        windowClients.forEach(function(client) {
          client.postMessage({ type: 'SUBSCRIPTION_EXPIRED' });
        });
      });
    })
  );
});

// ─── PUSH ALIMINDA TOKEN CANLI TUTMA ──────────────────────────────
function notifyClientsToRefreshToken() {
  clients.matchAll({ type: 'window', includeUncontrolled: true }).then(function(windowClients) {
    windowClients.forEach(function(client) {
      client.postMessage({ type: 'TOKEN_REFRESH_NEEDED' });
    });
  });
}

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
