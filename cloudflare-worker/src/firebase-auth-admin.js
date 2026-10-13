/**
 * Firebase Auth REST API wrapper for Cloudflare Workers
 * admin.auth().updateUser / deleteUser yerine Identity Toolkit REST API kullanır
 */

const AUTH_URL = 'https://identitytoolkit.googleapis.com/v1';

export class AuthClient {
  constructor(accessToken) {
    this.accessToken = accessToken;
  }

  get headers() {
    return {
      'Authorization': `Bearer ${this.accessToken}`,
      'Content-Type': 'application/json',
    };
  }

  /**
   * Kullanıcı bilgilerini güncelle (displayName, email, password)
   * admin.auth().updateUser() karşılığı
   */
  async updateUser(uid, updates) {
    const url = `${AUTH_URL}/accounts:update`;
    
    const body = { localId: uid };
    
    if (updates.password) body.password = updates.password;
    if (updates.displayName) body.displayName = updates.displayName;
    if (updates.email) body.email = updates.email;

    const res = await fetch(url, {
      method: 'POST',
      headers: this.headers,
      body: JSON.stringify(body),
    });

    if (!res.ok) {
      const error = await res.text();
      throw new Error(`updateUser failed for ${uid}: ${error}`);
    }

    return await res.json();
  }

  /**
   * Kullanıcıyı sil
   * admin.auth().deleteUser() karşılığı
   */
  async deleteUser(uid) {
    const url = `${AUTH_URL}/accounts:delete`;
    
    const res = await fetch(url, {
      method: 'POST',
      headers: this.headers,
      body: JSON.stringify({ localId: uid }),
    });

    if (!res.ok) {
      const error = await res.json().catch(() => ({}));
      const message = error?.error?.message || '';
      
      if (message === 'USER_NOT_FOUND') {
        return { code: 'auth/user-not-found' };
      }
      throw new Error(`deleteUser failed for ${uid}: ${JSON.stringify(error)}`);
    }

    return await res.json();
  }
}
