/**
 * WP Sayım — Cloudflare Worker
 * Firebase Functions'dan taşınan tüm backend mantığı
 * 
 * Bu worker şu işleri yapar:
 * 1. Flutter app'ten gelen HTTP isteklerini karşılar (bildirim, auth sync, vb.)
 * 2. Cron trigger'lar ile zamanlanmış görevleri çalıştırır
 * 
 * Firebase Admin SDK yerine REST API kullanır.
 */

import { getAccessToken, verifyIdToken } from './firebase-auth.js';
import { FirestoreClient, serverTimestamp, deleteField } from './firestore.js';
import { FCMClient } from './fcm.js';
import { AuthClient } from './firebase-auth-admin.js';

const PROJECT_ID = 'wp-sayim';

// ─── Yardımcı: Client'ları başlat ───
async function initClients(env) {
  const token = await getAccessToken(env.FIREBASE_SERVICE_ACCOUNT);
  return {
    db: new FirestoreClient(PROJECT_ID, token),
    fcm: new FCMClient(PROJECT_ID, token),
    auth: new AuthClient(token),
  };
}

// ─── Yardımcı: CORS headers ───
const CORS_HEADERS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization',
};

function jsonResponse(data, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { 'Content-Type': 'application/json', ...CORS_HEADERS },
  });
}

// ─── Yardımcı: Auth Middleware ───
async function authenticateRequest(request) {
  const authHeader = request.headers.get('Authorization');
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return null;
  }
  const idToken = authHeader.substring(7);
  try {
    return await verifyIdToken(idToken, PROJECT_ID);
  } catch {
    return null;
  }
}

// ─── HELPER: sendNotificationAndLog ───
// Orijinal Firebase Functions'taki sendNotificationAndLog'un birebir karşılığı
async function sendNotificationAndLog(db, fcm, { userId, title, body, type, relatedId, dataPayload, tag, link }) {
  try {
    const userDoc = await db.getDoc('users', userId);
    if (!userDoc) return;

    const fcmToken = userDoc.fcmToken;
    const hasEmail = userDoc.email && userDoc.email.trim() !== '';

    // E-posta adresi yoksa VE fcmToken varsa push notification at
    if (fcmToken && !hasEmail) {
      const safeTopic = tag ? (tag.length > 32 ? tag.substring(tag.length - 32) : tag) : '';

      const message = {
        token: fcmToken,
        notification: { title, body },
        apns: {
          headers: {
            'apns-priority': '10',
            'apns-push-type': 'alert',
          },
        },
        android: {
          priority: 'high',
          notification: {
            channelId: 'sayim_notifications',
            tag: tag,
          },
        },
        webpush: {
          headers: {
            Topic: safeTopic,
            Urgency: 'high',
          },
          notification: {
            title,
            body,
            icon: '/icons/Icon-192.png',
            badge: '/icons/Icon-192.png',
            requireInteraction: true,
          },
          fcmOptions: {
            link: link || 'https://lnyctophilia.github.io/WP_Sayim/?open_notifications=true',
          },
        },
        data: dataPayload,
      };

      try {
        await fcm.send(message);
      } catch (e) {
        console.error('Error sending push notification:', e);

        const invalidTokenCodes = [
          'messaging/registration-token-not-registered',
          'messaging/invalid-registration-token',
          'messaging/third-party-auth-error',
          'messaging/mismatched-credential',
        ];

        if (e.code && invalidTokenCodes.includes(e.code)) {
          console.log(`[TOKEN CLEANUP] Geçersiz token siliniyor. userId: ${userId}, hata: ${e.code}`);
          try {
            await db.updateDoc('users', userId, {
              fcmToken: deleteField(),
              fcmTokenInvalidatedAt: new Date().toISOString(),
              fcmTokenInvalidReason: e.code,
            });
          } catch (cleanupErr) {
            console.error('[TOKEN CLEANUP] Token silinirken hata:', cleanupErr);
          }
        }
      }
    }

    // Uygulama içi bildirimi her zaman kaydet
    await db.addDoc('notifications', {
      userId,
      title,
      body,
      type,
      relatedId: relatedId || '',
      createdAt: new Date().toISOString(),
      isRead: false,
    });
  } catch (error) {
    console.error('Error in sendNotificationAndLog:', error);
  }
}

// ─── HELPER: sendEmailJSEmail ───
async function sendEmailJSEmail(toEmail, subject, textContent, env) {
  try {
    const response = await fetch('https://api.emailjs.com/api/v1.0/email/send', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        service_id: 'service_qjvatbn',
        template_id: 'template_9wd7j5s',
        user_id: '6Ybd1Uu2O5Es_Rdtq',
        accessToken: env.EMAILJS_PRIVATE_KEY,
        template_params: {
          to_email: toEmail,
          subject,
          message: textContent,
        },
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

// ═══════════════════════════════════════════════════════════
// HTTP ROUTE HANDLERS (Flutter'dan çağrılacak)
// ═══════════════════════════════════════════════════════════

// 1. POST /api/notify/davet-created
async function handleDavetCreated(body, db, fcm) {
  const { davetId, davetData } = body;
  if (!davetData) return { ok: true, skipped: true };

  if (davetData.isPast === true) return { ok: true, skipped: 'past' };
  if (davetData.status === 'accepted' || davetData.status === 'declined') return { ok: true, skipped: 'status' };

  const staffId = davetData.userId;
  const sayimId = davetData.sayimId;
  if (!staffId) return { ok: true, skipped: 'no_userId' };

  const sayimDoc = await db.getDoc('sayimlar', sayimId);
  if (!sayimDoc) return { ok: true, skipped: 'no_sayim' };
  if (sayimDoc.status === 'closed') return { ok: true, skipped: 'sayim_closed' };

  const sayimName = sayimDoc.toplanmaYeri || 'Yeni Sayım';
  const creatorId = sayimDoc.createdBy;
  if (staffId === creatorId) return { ok: true, skipped: 'self_invite' };

  await sendNotificationAndLog(db, fcm, {
    userId: staffId,
    title: 'Yeni Sayım Daveti',
    body: `Seni "${sayimName}" isimli sayıma davet ettiler. Lütfen uygulamaya girip onay ver.`,
    type: 'davet',
    relatedId: davetId,
    dataPayload: { type: 'davet', davetId, sayimId },
    tag: `davet_${davetId}`,
  });

  return { ok: true };
}

// 2. POST /api/notify/davet-response
async function handleDavetResponse(body, db, fcm) {
  const { davetId, oldStatus, newStatus, userId: staffId, sayimId } = body;
  
  if (!oldStatus || !newStatus) return { ok: true, skipped: true };
  if (oldStatus === newStatus) return { ok: true, skipped: 'same_status' };
  if (newStatus === 'pending') return { ok: true, skipped: 'pending' };

  const statusStr = newStatus === 'accepted' ? 'kabul etti' : 'reddetti';

  const sayimDoc = await db.getDoc('sayimlar', sayimId);
  if (!sayimDoc) return { ok: true, skipped: 'no_sayim' };

  const sayimName = sayimDoc.toplanmaYeri || 'Bilinmeyen Sayım';
  const creatorId = sayimDoc.createdBy;
  if (staffId === creatorId) return { ok: true, skipped: 'self' };

  const staffDoc = await db.getDoc('users', staffId);
  const staffName = staffDoc ? (staffDoc.fullName || 'Bir personel') : 'Bir personel';

  await sendNotificationAndLog(db, fcm, {
    userId: creatorId,
    title: 'Davet Yanıtı',
    body: `${staffName}, "${sayimName}" sayım davetini ${statusStr}.`,
    type: 'davet_response',
    relatedId: davetId,
    dataPayload: { type: 'davet_response', davetId, sayimId },
    tag: `davet_response_${davetId}`,
  });

  return { ok: true };
}

// 2.5. POST /api/notify/davet-reminder
async function handleDavetReminder(body, db, fcm) {
  const { davetId, userId: staffId, sayimId } = body;

  const sayimDoc = await db.getDoc('sayimlar', sayimId);
  const sayimName = sayimDoc ? (sayimDoc.toplanmaYeri || 'Sayım') : 'Sayım';

  await sendNotificationAndLog(db, fcm, {
    userId: staffId,
    title: 'Yeni Sayım Daveti',
    body: `Seni "${sayimName}" isimli sayıma davet ettiler. Lütfen uygulamaya girip onay ver.`,
    type: 'davet_reminder',
    relatedId: davetId,
    dataPayload: { type: 'davet', davetId, sayimId },
    tag: `davet_${davetId}`,
  });

  return { ok: true };
}

// 3. POST /api/notify/davet-cancelled
async function handleDavetCancelled(body, db, fcm) {
  const { davetId, davetData } = body;
  if (!davetData) return { ok: true, skipped: true };
  if (davetData.status !== 'accepted') return { ok: true, skipped: 'not_accepted' };
  if (davetData.silentDelete === true) return { ok: true, skipped: 'silent' };

  const staffId = davetData.userId;
  const sayimId = davetData.sayimId;

  const sayimDoc = await db.getDoc('sayimlar', sayimId);
  let notificationBody = 'Kabul ettiğiniz bir sayım iptal edildi, lütfen uygulamadan kontrol edin.';
  if (sayimDoc && sayimDoc.toplanmaYeri) {
    notificationBody = `Kabul ettiğin "${sayimDoc.toplanmaYeri}" isimli sayım iptal edildi.`;
  }

  await sendNotificationAndLog(db, fcm, {
    userId: staffId,
    title: 'Sayım İptali',
    body: notificationBody,
    type: 'davet_cancelled',
    relatedId: sayimId,
    dataPayload: { type: 'davet_cancelled', sayimId },
    tag: `davet_${davetId}`,
  });

  return { ok: true };
}

// 4. POST /api/sync-user-auth
async function handleSyncUserAuth(body, db, authClient) {
  const { userId, oldData, newData } = body;
  if (!oldData || !newData) return { ok: true, skipped: true };

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
      await authClient.updateUser(userId, updatePayload);
      console.log(`Successfully synced auth for user: ${userId}`);

      // Şifre alanını Firestore'dan sil
      if (updatePayload.password) {
        await db.updateDoc('users', userId, {
          password: deleteField(),
        });
        console.log(`Deleted plaintext password from Firestore for user: ${userId}`);
      }
    } catch (error) {
      console.error(`Error syncing auth for user: ${userId}`, error);
    }
  }

  return { ok: true };
}

// 5. POST /api/delete-user-auth
async function handleDeleteUserAuth(body, authClient) {
  const { userId } = body;
  try {
    const result = await authClient.deleteUser(userId);
    if (result && result.code === 'auth/user-not-found') {
      console.log(`Auth user ${userId} already deleted or does not exist.`);
    } else {
      console.log(`Successfully deleted auth user: ${userId}`);
    }
  } catch (error) {
    console.error(`Error deleting auth user: ${userId}`, error);
  }
  return { ok: true };
}

// 7. POST /api/notify/approval
async function handleApprovalNotification(body, db, fcm, env) {
  const { userId, oldIsApproved, newIsApproved, email } = body;

  if (oldIsApproved || !newIsApproved) return { ok: true, skipped: 'not_approval_change' };

  const hasEmail = email && email.trim() !== '';

  if (hasEmail) {
    await sendEmailJSEmail(
      email.trim(),
      'WP Sayım - Hesabınız Onaylandı!',
      'WP Sayım uygulamasına kayıt başvurunuz onaylandı. Artık telefon numarası ve şifreniz ile giriş yapabilirsiniz.',
      env
    );

    await db.addDoc('notifications', {
      userId,
      title: 'Hesabınız Onaylandı!',
      body: 'WP Sayım uygulamasına kayıt başvurunuz onaylandı. Artık giriş yapabilirsiniz.',
      type: 'approval',
      relatedId: userId,
      createdAt: new Date().toISOString(),
      isRead: false,
    });
  } else {
    await sendNotificationAndLog(db, fcm, {
      userId,
      title: 'Hesabınız Onaylandı!',
      body: 'WP Sayım uygulamasına kayıt başvurunuz onaylandı. Artık giriş yapabilirsiniz.',
      type: 'approval',
      relatedId: userId,
      dataPayload: { type: 'approval', userId },
      tag: `approval_${userId}`,
      link: 'https://lnyctophilia.github.io/WP_Sayim/',
    });
  }

  return { ok: true };
}

// 11. POST /api/notify/test
async function handleTestNotification(body, db, fcm, env) {
  const { userId } = body;
  if (!userId) return { ok: true, skipped: 'no_userId' };

  const userDoc = await db.getDoc('users', userId);
  if (!userDoc) return { ok: true, skipped: 'no_user' };

  const hasEmail = userDoc.email && userDoc.email.trim() !== '';
  const fcmToken = userDoc.fcmToken;

  if (hasEmail) {
    await sendEmailJSEmail(
      userDoc.email,
      'WP Sayım - Bildirim Testi',
      'Bu bir test e-postasıdır. Eğer bu mesajı alıyorsanız, bildirim sisteminiz başarıyla çalışıyor demektir.',
      env
    );

    await db.addDoc('notifications', {
      userId,
      title: 'Test E-postası Gönderildi',
      body: 'E-posta adresinize test maili gönderildi. Lütfen gelen kutunuzu kontrol edin.',
      type: 'test',
      relatedId: '',
      createdAt: new Date().toISOString(),
      isRead: false,
    });
  } else {
    if (fcmToken) {
      const message = {
        token: fcmToken,
        notification: {
          title: 'Test Bildirimi',
          body: 'Uygulama kapalıyken (veya arka plandayken) de bildirim alabiliyorsunuz. Harika!',
        },
        apns: {
          headers: { 'apns-priority': '10', 'apns-push-type': 'alert' },
        },
        android: {
          priority: 'high',
          notification: { channelId: 'sayim_notifications', tag: `test_${userId}` },
        },
        webpush: {
          headers: { Urgency: 'high' },
          notification: {
            title: 'Test Bildirimi',
            body: 'Uygulama kapalıyken (veya arka plandayken) de bildirim alabiliyorsunuz. Harika!',
            icon: '/icons/Icon-192.png',
            badge: '/icons/Icon-192.png',
          },
          fcmOptions: { link: 'https://lnyctophilia.github.io/WP_Sayim/' },
        },
        data: { type: 'test' },
      };

      try {
        await fcm.send(message);
      } catch (pushErr) {
        console.error('sendTestNotification: Push error:', pushErr);

        const invalidTokenCodes = [
          'messaging/registration-token-not-registered',
          'messaging/invalid-registration-token',
          'messaging/third-party-auth-error',
          'messaging/mismatched-credential',
        ];
        if (pushErr.code && invalidTokenCodes.includes(pushErr.code)) {
          try {
            await db.updateDoc('users', userId, {
              fcmToken: deleteField(),
              fcmTokenInvalidatedAt: new Date().toISOString(),
              fcmTokenInvalidReason: pushErr.code,
            });
          } catch (cleanupErr) {
            console.error('[TOKEN CLEANUP] Token silinirken hata:', cleanupErr);
          }
        }
      }
    }

    await db.addDoc('notifications', {
      userId,
      title: 'Test Bildirimi',
      body: 'Uygulama kapalıyken (veya arka plandayken) de bildirim alabiliyorsunuz. Harika!',
      type: 'test',
      relatedId: '',
      createdAt: new Date().toISOString(),
      isRead: false,
    });
  }

  return { ok: true };
}

// 12. POST /api/notify/davet-grup-changed
async function handleDavetGrupChanged(body, db, fcm) {
  const { davetId, oldGrupId, newGrupId, userId: staffId, sayimId, status, isPast } = body;

  if (oldGrupId === newGrupId) return { ok: true, skipped: 'same_grup' };
  if (isPast === true) return { ok: true, skipped: 'past' };
  if (status !== 'accepted') return { ok: true, skipped: 'not_accepted' };

  const sayimDoc = await db.getDoc('sayimlar', sayimId);
  if (!sayimDoc) return { ok: true, skipped: 'no_sayim' };
  if (sayimDoc.status === 'closed') return { ok: true, skipped: 'closed' };

  const sayimName = sayimDoc.toplanmaYeri || 'Sayım';
  const gruplar = sayimDoc.gruplar || [];
  const grup = gruplar.find(g => g.grupId === newGrupId);
  const yeniSaat = grup ? grup.saat : '';

  await sendNotificationAndLog(db, fcm, {
    userId: staffId,
    title: 'Sayım Saati Güncellendi',
    body: `"${sayimName}" sayımındaki saatiniz ${yeniSaat} olarak güncellenmiştir.`,
    type: 'davet_time_updated',
    relatedId: sayimId,
    dataPayload: { type: 'davet_time_updated', sayimId, davetId },
    tag: `davet_time_updated_${davetId}`,
  });

  return { ok: true };
}

// 13. POST /api/notify/sayim-time-changed
async function handleSayimTimeChanged(body, db, fcm) {
  const { sayimId, oldGruplar, newGruplar } = body;
  if (!oldGruplar || !newGruplar) return { ok: true, skipped: true };

  const changedGroups = [];
  for (const newGrup of newGruplar) {
    const oldGrup = oldGruplar.find(g => g.grupId === newGrup.grupId);
    if (oldGrup && oldGrup.saat !== newGrup.saat) {
      changedGroups.push(newGrup);
    }
  }

  if (changedGroups.length === 0) return { ok: true, skipped: 'no_time_change' };

  const sayimDoc = await db.getDoc('sayimlar', sayimId);
  if (!sayimDoc || sayimDoc.status === 'closed') return { ok: true, skipped: 'closed_or_missing' };
  const sayimName = sayimDoc.toplanmaYeri || 'Sayım';

  const davetler = await db.query('davetler', {
    where: [
      { field: 'sayimId', op: '==', value: sayimId },
      { field: 'status', op: '==', value: 'accepted' },
    ],
  });

  for (const davet of davetler) {
    const changedGrup = changedGroups.find(g => g.grupId === davet.grupId);
    if (changedGrup) {
      await sendNotificationAndLog(db, fcm, {
        userId: davet.userId,
        title: 'Sayım Saati Güncellendi',
        body: `"${sayimName}" sayımındaki saatiniz ${changedGrup.saat} olarak güncellenmiştir.`,
        type: 'sayim_time_updated',
        relatedId: sayimId,
        dataPayload: { type: 'sayim_time_updated', sayimId, davetId: davet.id },
        tag: `sayim_time_updated_${davet.id}`,
      });
    }
  }

  return { ok: true };
}

// ═══════════════════════════════════════════════════════════
// CRON HANDLERS (Zamanlanmış görevler)
// ═══════════════════════════════════════════════════════════

// 6. sayimAutoReminder (her 2 saatte)
async function cronSayimAutoReminder(db, fcm) {
  const now = new Date();
  const nowMs = now.getTime();
  const startOfDay = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  const endOfWindow = new Date(startOfDay.getTime() + 36 * 60 * 60 * 1000);

  const report = {
    now: now.toISOString(),
    foundSayimlar: 0,
    matchedDavetler: 0,
    sentNotifications: 0,
    details: [],
  };

  const sayimlar = await db.query('sayimlar', {
    where: [
      { field: 'date', op: '>=', value: startOfDay },
      { field: 'date', op: '<=', value: endOfWindow },
    ],
  });

  report.foundSayimlar = sayimlar.length;
  if (sayimlar.length === 0) return report;

  for (const sayim of sayimlar) {
    if (!sayim || !sayim.date || !sayim.gruplar) continue;

    const davetler = await db.query('davetler', {
      where: [
        { field: 'sayimId', op: '==', value: sayim.id },
        { field: 'status', op: '==', value: 'accepted' },
      ],
    });

    if (davetler.length === 0) continue;

    for (const davet of davetler) {
      report.matchedDavetler++;
      if (davet.autoReminderSent === true) {
        report.details.push({ davetId: davet.id, status: 'already_sent' });
        continue;
      }

      const grup = (sayim.gruplar || []).find(g => g.grupId === davet.grupId);
      if (!grup || !grup.saat) {
        report.details.push({ davetId: davet.id, status: 'no_group_or_time' });
        continue;
      }

      // Sayım tarihini Türkiye saatine çevir
      const sayimDateObj = sayim.date instanceof Date ? sayim.date : new Date(sayim.date);
      const trtDateMs = sayimDateObj.getTime() + (3 * 60 * 60 * 1000);
      const trtDateObj = new Date(trtDateMs);

      const year = trtDateObj.getUTCFullYear();
      const month = String(trtDateObj.getUTCMonth() + 1).padStart(2, '0');
      const day = String(trtDateObj.getUTCDate()).padStart(2, '0');

      const isoString = `${year}-${month}-${day}T${grup.saat}:00+03:00`;
      const finalSayimDate = new Date(isoString);

      const diffHours = (finalSayimDate.getTime() - nowMs) / (1000 * 60 * 60);

      if (diffHours > 0 && diffHours <= 3) {
        const userDoc = await db.getDoc('users', davet.userId);
        if (!userDoc) {
          report.details.push({ davetId: davet.id, userId: davet.userId, status: 'user_not_found' });
          continue;
        }
        if (userDoc.sayimReminderEnabled === false) {
          report.details.push({ davetId: davet.id, userId: davet.userId, status: 'reminder_disabled_by_user' });
          continue;
        }

        const sayimName = sayim.toplanmaYeri || 'Sayım';

        await sendNotificationAndLog(db, fcm, {
          userId: davet.userId,
          title: 'Yaklaşan Sayım',
          body: `Bugün saat ${grup.saat}'te "${sayimName}" sayımı var. Lütfen vaktinde orada olun.`,
          type: 'sayim_auto_reminder',
          relatedId: davet.id,
          dataPayload: { type: 'sayim_auto_reminder', davetId: davet.id, sayimId: sayim.id },
          tag: `sayim_auto_reminder_${davet.id}`,
        });

        try {
          await db.updateDoc('davetler', davet.id, { autoReminderSent: true });
        } catch (e) {
          console.error('Error updating autoReminderSent for davet ' + davet.id, e);
        }

        report.sentNotifications++;
        report.details.push({ davetId: davet.id, userId: davet.userId, status: 'sent', diffHours });
      } else {
        report.details.push({ davetId: davet.id, status: 'not_in_3h_window', diffHours });
      }
    }
  }

  return report;
}

// 14. cleanupOldNotifications (Pazar 05:00 TR)
async function cronCleanupOldNotifications(db) {
  const now = new Date();
  const thirtyDaysAgo = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);

  const oldNotifications = await db.query('notifications', {
    where: [
      { field: 'createdAt', op: '<', value: thirtyDaysAgo },
    ],
    limit: 500,
  });

  if (oldNotifications.length === 0) {
    console.log('[CleanupNotifications] No old notifications found to delete.');
    return;
  }

  await db.batchDelete(oldNotifications);
  console.log(`[CleanupNotifications] Deleted ${oldNotifications.length} old notifications.`);
}

// hardDeleteSoftDeletedUsers (Her ayın 16'sı 04:00 TR)
async function cronHardDeleteSoftDeletedUsers(db) {
  const now = new Date();
  console.log(`[HardDelete] Running hard-delete check at ${now.toISOString()}`);

  const users = await db.query('users', {
    where: [
      { field: 'isDeleted', op: '==', value: false },
    ],
  });

  // Client-side filter: softDeletedAt != null
  const softDeletedUsers = users.filter(u => u.softDeletedAt != null && u.softDeletedAt !== undefined);

  if (softDeletedUsers.length === 0) {
    console.log('[HardDelete] No soft-deleted users found. Exiting.');
    return;
  }

  console.log(`[HardDelete] Found ${softDeletedUsers.length} soft-deleted user(s) to evaluate.`);

  let deletedCount = 0;
  let skippedCount = 0;

  for (const userData of softDeletedUsers) {
    const userId = userData.id;
    const softDeletedAt = userData.softDeletedAt instanceof Date
      ? userData.softDeletedAt
      : new Date(userData.softDeletedAt);
    const username = userData.username || '';

    try {
      // personel_takvimi/{userId}/gunler altında softDeletedAt'tan sonraki kayıtları ara
      const workDocs = await db.querySubcollection('personel_takvimi', userId, 'gunler', {
        where: [
          { field: 'tarih', op: '>=', value: softDeletedAt },
        ],
        limit: 1,
      });

      const hasWorkedAfterDeletion = workDocs.length > 0;

      let deleteTargetDate;
      if (hasWorkedAfterDeletion) {
        deleteTargetDate = new Date(softDeletedAt.getFullYear(), softDeletedAt.getMonth() + 1, 16, 0, 0, 0);
      } else {
        deleteTargetDate = new Date(softDeletedAt.getFullYear(), softDeletedAt.getMonth(), 16, 0, 0, 0);
        if (softDeletedAt.getDate() > 16) {
          deleteTargetDate = new Date(softDeletedAt.getFullYear(), softDeletedAt.getMonth() + 1, 16, 0, 0, 0);
        }
      }

      if (now >= deleteTargetDate) {
        const newUsername = `${username}_deleted_${Date.now()}`;
        await db.updateDoc('users', userId, {
          active: false,
          isDeleted: true,
          username: newUsername,
          phone: newUsername,
        });
        console.log(`[HardDelete] Hard-deleted user ${userId} (${username}). Target was ${deleteTargetDate.toISOString()}, worked=${hasWorkedAfterDeletion}`);
        deletedCount++;
      } else {
        console.log(`[HardDelete] Skipped user ${userId} (${username}). Target ${deleteTargetDate.toISOString()} not yet reached. worked=${hasWorkedAfterDeletion}`);
        skippedCount++;
      }
    } catch (err) {
      console.error(`[HardDelete] Error processing user ${userId}:`, err);
    }
  }

  console.log(`[HardDelete] Done. Deleted: ${deletedCount}, Skipped: ${skippedCount}`);
}

// 15. weeklyFirestoreBackup (Pazar 03:00 TR)
async function cronWeeklyFirestoreBackup(env) {
  const token = await getAccessToken(env.FIREBASE_SERVICE_ACCOUNT);
  const bucket = `gs://${PROJECT_ID}-backups`;
  const url = `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default):exportDocuments`;

  try {
    const res = await fetch(url, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        outputUriPrefix: bucket,
        collectionIds: [], // all collections
      }),
    });

    if (res.ok) {
      console.log('Backup successfully started');
    } else {
      console.error('Backup failed:', await res.text());
    }
  } catch (err) {
    console.error('Backup failed', err);
  }
}

// 16. cleanupOldBackups (Pazar 04:00 TR)
async function cronCleanupOldBackups(env) {
  const token = await getAccessToken(env.FIREBASE_SERVICE_ACCOUNT);
  const bucketName = `${PROJECT_ID}-backups`;
  const fourteenDaysAgo = new Date(Date.now() - 14 * 24 * 60 * 60 * 1000);

  try {
    // List objects in GCS bucket
    const listUrl = `https://storage.googleapis.com/storage/v1/b/${bucketName}/o`;
    const res = await fetch(listUrl, {
      headers: { 'Authorization': `Bearer ${token}` },
    });

    if (!res.ok) {
      console.error('Failed to list backup files:', await res.text());
      return;
    }

    const data = await res.json();
    const items = data.items || [];
    let deletedCount = 0;

    for (const item of items) {
      const created = new Date(item.timeCreated);
      if (created < fourteenDaysAgo) {
        const deleteUrl = `https://storage.googleapis.com/storage/v1/b/${bucketName}/o/${encodeURIComponent(item.name)}`;
        await fetch(deleteUrl, {
          method: 'DELETE',
          headers: { 'Authorization': `Bearer ${token}` },
        });
        deletedCount++;
      }
    }

    console.log(`Cleaned up ${deletedCount} old backup files.`);
  } catch (err) {
    console.error('Cleanup failed', err);
  }
}

// ═══════════════════════════════════════════════════════════
// ROUTER
// ═══════════════════════════════════════════════════════════

const routes = {
  '/api/notify/davet-created': handleDavetCreated,
  '/api/notify/davet-response': handleDavetResponse,
  '/api/notify/davet-reminder': handleDavetReminder,
  '/api/notify/davet-cancelled': handleDavetCancelled,
  '/api/sync-user-auth': 'sync-user-auth',
  '/api/delete-user-auth': 'delete-user-auth',
  '/api/notify/approval': 'approval',
  '/api/notify/test': handleTestNotification,
  '/api/notify/davet-grup-changed': handleDavetGrupChanged,
  '/api/notify/sayim-time-changed': handleSayimTimeChanged,
};

export default {
  async fetch(request, env, ctx) {
    // CORS preflight
    if (request.method === 'OPTIONS') {
      return new Response(null, { headers: CORS_HEADERS });
    }

    const url = new URL(request.url);
    const path = url.pathname;

    // Health check
    if (path === '/' || path === '/health') {
      return jsonResponse({ status: 'ok', worker: 'wp-sayim-api' });
    }


    if (request.method !== 'POST') {
      return jsonResponse({ error: 'Method not allowed' }, 405);
    }

    // Auth check — Flutter'dan gelen idToken doğrula
    const user = await authenticateRequest(request);
    if (!user) {
      return jsonResponse({ error: 'Unauthorized' }, 401);
    }

    const { db, fcm, auth } = await initClients(env);

    try {
      const body = await request.json();

      // Special routes
      if (path === '/api/sync-user-auth') {
        const result = await handleSyncUserAuth(body, db, auth);
        return jsonResponse(result);
      }

      if (path === '/api/delete-user-auth') {
        const result = await handleDeleteUserAuth(body, auth);
        return jsonResponse(result);
      }

      if (path === '/api/notify/approval') {
        const result = await handleApprovalNotification(body, db, fcm, env);
        return jsonResponse(result);
      }

      // Standard notification routes
      const handler = routes[path];
      if (handler && typeof handler === 'function') {
        const result = await handler(body, db, fcm, env);
        return jsonResponse(result);
      }

      return jsonResponse({ error: 'Not found' }, 404);
    } catch (error) {
      console.error(`Error handling ${path}:`, error);
      return jsonResponse({ error: error.message || 'Internal server error' }, 500);
    }
  },

  // Cron trigger handler
  async scheduled(event, env, ctx) {
    const { db, fcm } = await initClients(env);
    const cronPattern = event.cron;

    console.log(`[CRON] Running: ${cronPattern} at ${new Date().toISOString()}`);

    try {
      switch (cronPattern) {
        case '0 */2 * * *':
          await cronSayimAutoReminder(db, fcm);
          break;
        case '0 2 * * SUN':
        case '0 2 * * 0':
          await cronCleanupOldNotifications(db);
          break;
        case '0 22 * * SAT':
        case '0 22 * * 6':
          await cronWeeklyFirestoreBackup(env);
          break;
        case '0 1 * * SUN':
        case '0 1 * * 0':
          await cronCleanupOldBackups(env);
          break;
        case '0 1 16 * *':
          await cronHardDeleteSoftDeletedUsers(db);
          break;
        default:
          console.log(`[CRON] Unknown cron pattern: ${cronPattern}`);
      }
    } catch (error) {
      console.error(`[CRON] Error in ${cronPattern}:`, error);
    }
  },
};
