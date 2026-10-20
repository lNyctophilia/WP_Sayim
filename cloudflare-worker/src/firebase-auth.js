/**
 * Firebase Auth helper — Service Account JWT → OAuth2 Access Token
 * Cloudflare Workers'da firebase-admin kullanılamadığı için
 * tüm Firebase etkileşimleri REST API üzerinden yapılır.
 */

// ─── Base64url encode/decode ───
function base64urlEncode(data) {
  let bytes;
  if (typeof data === 'string') {
    // TextEncoder ile UTF-8 → Uint8Array
    bytes = new TextEncoder().encode(data);
  } else {
    bytes = data;
  }
  // Uint8Array → binary string → btoa
  let binary = '';
  const len = bytes.byteLength || bytes.length;
  for (let i = 0; i < len; i++) {
    binary += String.fromCharCode(bytes[i]);
  }
  return btoa(binary)
    .replace(/\+/g, '-')
    .replace(/\//g, '_')
    .replace(/=+$/, '');
}

/**
 * PEM formatındaki private key'i PKCS8 CryptoKey'e çevir
 */
async function importPrivateKey(pem) {
  const pemContents = pem
    .replace(/-----BEGIN PRIVATE KEY-----/g, '')
    .replace(/-----END PRIVATE KEY-----/g, '')
    .replace(/\s/g, '');
  
  const binaryDer = Uint8Array.from(atob(pemContents), c => c.charCodeAt(0));
  
  return crypto.subtle.importKey(
    'pkcs8',
    binaryDer.buffer,
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false,
    ['sign']
  );
}

/**
 * Google OAuth2 access token al (Service Account JWT ile)
 */
let cachedToken = null;
let tokenExpiry = 0;

export async function getAccessToken(serviceAccount) {
  const now = Math.floor(Date.now() / 1000);
  
  // Cache'den döndür (5 dakika erken expire et)
  if (cachedToken && tokenExpiry > now + 300) {
    return cachedToken;
  }
  
  const sa = typeof serviceAccount === 'string' ? JSON.parse(serviceAccount) : serviceAccount;
  
  const header = { alg: 'RS256', typ: 'JWT' };
  const payload = {
    iss: sa.client_email,
    scope: [
      'https://www.googleapis.com/auth/datastore',
      'https://www.googleapis.com/auth/firebase.messaging',
      'https://www.googleapis.com/auth/identitytoolkit',
      'https://www.googleapis.com/auth/cloud-platform',
    ].join(' '),
    aud: 'https://oauth2.googleapis.com/token',
    iat: now,
    exp: now + 3600,
  };
  
  const encodedHeader = base64urlEncode(JSON.stringify(header));
  const encodedPayload = base64urlEncode(JSON.stringify(payload));
  const signingInput = `${encodedHeader}.${encodedPayload}`;
  
  const key = await importPrivateKey(sa.private_key);
  const signature = await crypto.subtle.sign(
    'RSASSA-PKCS1-v1_5',
    key,
    new TextEncoder().encode(signingInput)
  );
  
  const encodedSignature = base64urlEncode(new Uint8Array(signature));
  const jwt = `${signingInput}.${encodedSignature}`;
  
  // Exchange JWT for access token
  const response = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${jwt}`,
  });
  
  if (!response.ok) {
    const err = await response.text();
    throw new Error(`OAuth2 token exchange failed: ${err}`);
  }
  
  const data = await response.json();
  cachedToken = data.access_token;
  tokenExpiry = now + data.expires_in;
  
  return cachedToken;
}

/**
 * Firebase ID Token doğrulama (Flutter'dan gelen kullanıcı auth token'ı)
 * JWT'yi decode edip exp, aud, iss, iat, sub kontrolü yapar.
 */
export async function verifyIdToken(idToken, projectId) {
  try {
    const parts = idToken.split('.');
    if (parts.length !== 3) throw new Error('Invalid token format');

    const payload = JSON.parse(atob(parts[1].replace(/-/g, '+').replace(/_/g, '/')));
    const now = Math.floor(Date.now() / 1000);

    // Token süresi dolmuş mu?
    if (!payload.exp || payload.exp < now) throw new Error('Token expired');

    // Doğru proje mi?
    if (payload.aud !== projectId) throw new Error('Invalid audience');

    // Doğru issuer mı?
    const expectedIssuer = `https://securetoken.google.com/${projectId}`;
    if (payload.iss !== expectedIssuer) throw new Error('Invalid issuer');

    // Gelecek tarihli token mı? (replay attack koruması)
    if (payload.iat && payload.iat > now + 60) throw new Error('Token issued in the future');

    // Kullanıcı ID'si var mı?
    const uid = payload.sub || payload.user_id;
    if (!uid) throw new Error('No user ID in token');

    return { uid, email: payload.email };
  } catch (e) {
    throw new Error(`Invalid ID token: ${e.message}`);
  }
}
