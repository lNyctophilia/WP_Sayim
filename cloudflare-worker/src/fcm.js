/**
 * FCM HTTP v1 API wrapper for Cloudflare Workers
 * firebase-admin messaging yerine FCM REST API kullanır
 * 
 * Retry mekanizması + iyileştirilmiş hata ayrıştırma:
 * - Geçici hatalar (500, 503, 429, belirsiz 404) → exponential backoff ile retry
 * - Kesin geçersiz token (UNREGISTERED) → hemen hata fırlat
 * - Belirsiz token hataları → hata kodu ile birlikte fırlat (soft-invalidate için)
 */

const FCM_URL = 'https://fcm.googleapis.com/v1/projects';
const MAX_RETRIES = 3;

export class FCMClient {
  constructor(projectId, accessToken) {
    this.projectId = projectId;
    this.accessToken = accessToken;
  }

  /**
   * Push notification gönder (retry mekanizması ile)
   * @returns {Promise<boolean>} başarılı mı
   */
  async send(message, _retryCount = 0) {
    const url = `${FCM_URL}/${this.projectId}/messages:send`;
    
    const res = await fetch(url, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${this.accessToken}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ message }),
    });

    if (!res.ok) {
      const error = await res.json().catch(() => ({}));
      const statusCode = error?.error?.code;
      const detailErrorCode = error?.error?.details?.[0]?.errorCode || '';
      const errorMessage = (error?.error?.message || '').toLowerCase();
      
      // Retry edilebilir hatalar: 500, 503, 429 ve belirsiz 404'ler
      const isRetryable = [500, 503].includes(statusCode) || 
                          statusCode === 429 ||
                          (statusCode === 404 && !this._isDefinitelyUnregistered(detailErrorCode, errorMessage));
      
      if (isRetryable && _retryCount < MAX_RETRIES) {
        const delay = Math.pow(2, _retryCount) * 500; // 500ms → 1s → 2s
        await new Promise(r => setTimeout(r, delay));
        console.log(`[FCM Retry] Deneme ${_retryCount + 1}/${MAX_RETRIES}, ${delay}ms beklendi. Status: ${statusCode}`);
        return this.send(message, _retryCount + 1);
      }
      
      // FCM hata kodlarını Firebase SDK formatına çevir
      const errorInfo = {
        code: this._mapErrorCode(detailErrorCode, error),
        message: error?.error?.message || 'Unknown FCM error',
        raw: error,
        retries: _retryCount,
      };
      
      throw errorInfo;
    }

    return true;
  }

  /**
   * Token'ın kesinlikle geçersiz (unregistered) olup olmadığını belirler.
   * Belirsiz 404'lerde false döner → retry yapılır.
   */
  _isDefinitelyUnregistered(detailErrorCode, errorMessage) {
    return detailErrorCode === 'UNREGISTERED' || 
           errorMessage.includes('not registered') ||
           errorMessage.includes('registration token is not a valid');
  }

  _mapErrorCode(detailErrorCode, error) {
    const statusCode = error?.error?.code;
    const message = (error?.error?.message || '').toLowerCase();
    
    // Kesin token geçersizliği — FCM details'de UNREGISTERED varsa
    if (detailErrorCode === 'UNREGISTERED' || message.includes('not registered')) {
      return 'messaging/registration-token-not-registered';
    }
    
    // Geçersiz token formatı
    if (statusCode === 400) {
      if (message.includes('invalid registration') || message.includes('invalid argument')) {
        return 'messaging/invalid-registration-token';
      }
    }
    
    // 404 ama UNREGISTERED olmayan — retry sonrası hâlâ başarısızsa geçici hata
    if (statusCode === 404) {
      return 'messaging/unknown-404';
    }
    
    // Auth hataları
    if (statusCode === 401 || statusCode === 403) {
      if (message.includes('third-party') || message.includes('auth')) {
        return 'messaging/third-party-auth-error';
      }
      return 'messaging/mismatched-credential';
    }
    
    return `messaging/unknown-${statusCode || 'error'}`;
  }
}
