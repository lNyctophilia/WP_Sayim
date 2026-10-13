/**
 * FCM HTTP v1 API wrapper for Cloudflare Workers
 * firebase-admin messaging yerine FCM REST API kullanır
 */

const FCM_URL = 'https://fcm.googleapis.com/v1/projects';

export class FCMClient {
  constructor(projectId, accessToken) {
    this.projectId = projectId;
    this.accessToken = accessToken;
  }

  /**
   * Push notification gönder
   * @returns {Promise<boolean>} başarılı mı
   */
  async send(message) {
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
      const errorCode = error?.error?.details?.[0]?.errorCode || error?.error?.status || '';
      
      // FCM hata kodlarını Firebase SDK formatına çevir
      const errorInfo = {
        code: this._mapErrorCode(errorCode, error),
        message: error?.error?.message || 'Unknown FCM error',
        raw: error,
      };
      
      throw errorInfo;
    }

    return true;
  }

  _mapErrorCode(errorCode, error) {
    const statusCode = error?.error?.code;
    const message = (error?.error?.message || '').toLowerCase();
    
    if (statusCode === 404 || message.includes('not found') || message.includes('not registered')) {
      return 'messaging/registration-token-not-registered';
    }
    if (statusCode === 400) {
      if (message.includes('invalid registration') || message.includes('invalid argument')) {
        return 'messaging/invalid-registration-token';
      }
    }
    if (statusCode === 401 || statusCode === 403) {
      if (message.includes('third-party') || message.includes('auth')) {
        return 'messaging/third-party-auth-error';
      }
      return 'messaging/mismatched-credential';
    }
    return `messaging/unknown-${statusCode || 'error'}`;
  }
}
