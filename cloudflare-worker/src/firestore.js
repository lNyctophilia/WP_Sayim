/**
 * Firestore REST API wrapper for Cloudflare Workers
 * firebase-admin yerine Firestore REST API v1 kullanır
 */

const BASE_URL = 'https://firestore.googleapis.com/v1';

function docPath(projectId, collection, docId) {
  return `projects/${projectId}/databases/(default)/documents/${collection}/${docId}`;
}

function collectionPath(projectId, collection) {
  return `projects/${projectId}/databases/(default)/documents/${collection}`;
}

// ─── Firestore Value Converters ───

/**
 * JS value → Firestore Value format
 */
function toFirestoreValue(value) {
  if (value === null || value === undefined) return { nullValue: null };
  if (typeof value === 'string') return { stringValue: value };
  if (typeof value === 'boolean') return { booleanValue: value };
  if (typeof value === 'number') {
    if (Number.isInteger(value)) return { integerValue: String(value) };
    return { doubleValue: value };
  }
  if (value instanceof Date) {
    return { timestampValue: value.toISOString() };
  }
  if (value && value._serverTimestamp) {
    // Server timestamp placeholder — will use commit time
    return { timestampValue: new Date().toISOString() };
  }
  if (value && value._delete) {
    return null; // Will be handled during update
  }
  if (Array.isArray(value)) {
    return { arrayValue: { values: value.map(toFirestoreValue) } };
  }
  if (typeof value === 'object') {
    const fields = {};
    for (const [k, v] of Object.entries(value)) {
      const fv = toFirestoreValue(v);
      if (fv !== null) fields[k] = fv;
    }
    return { mapValue: { fields } };
  }
  return { stringValue: String(value) };
}

/**
 * Firestore Value → JS value
 */
function fromFirestoreValue(value) {
  if (!value) return null;
  if ('stringValue' in value) return value.stringValue;
  if ('integerValue' in value) return parseInt(value.integerValue, 10);
  if ('doubleValue' in value) return value.doubleValue;
  if ('booleanValue' in value) return value.booleanValue;
  if ('nullValue' in value) return null;
  if ('timestampValue' in value) return new Date(value.timestampValue);
  if ('arrayValue' in value) {
    return (value.arrayValue.values || []).map(fromFirestoreValue);
  }
  if ('mapValue' in value) {
    return fromFirestoreFields(value.mapValue.fields || {});
  }
  if ('geoPointValue' in value) return value.geoPointValue;
  if ('referenceValue' in value) return value.referenceValue;
  return null;
}

/**
 * Firestore fields object → plain JS object
 */
function fromFirestoreFields(fields) {
  const result = {};
  for (const [key, value] of Object.entries(fields)) {
    result[key] = fromFirestoreValue(value);
  }
  return result;
}

/**
 * Firestore document → { id, ...data }
 */
function parseDoc(doc) {
  if (!doc || !doc.name) return null;
  const parts = doc.name.split('/');
  const id = parts[parts.length - 1];
  const data = fromFirestoreFields(doc.fields || {});
  return { id, ...data, _ref: doc.name };
}

// ─── Firestore REST API Methods ───

export class FirestoreClient {
  constructor(projectId, accessToken) {
    this.projectId = projectId;
    this.accessToken = accessToken;
    this.baseUrl = `${BASE_URL}/projects/${projectId}/databases/(default)/documents`;
  }

  get headers() {
    return {
      'Authorization': `Bearer ${this.accessToken}`,
      'Content-Type': 'application/json',
    };
  }

  /**
   * Tek bir doküman getir
   */
  async getDoc(collection, docId) {
    const url = `${this.baseUrl}/${collection}/${docId}`;
    const res = await fetch(url, { headers: this.headers });
    if (!res.ok) {
      if (res.status === 404) return null;
      throw new Error(`getDoc failed: ${await res.text()}`);
    }
    return parseDoc(await res.json());
  }

  /**
   * Koleksiyon sorgusu (where, orderBy, limit)
   */
  async query(collection, { where = [], orderBy, limit, startAt } = {}) {
    const url = `${BASE_URL}/projects/${this.projectId}/databases/(default)/documents:runQuery`;
    
    const structuredQuery = {
      from: [{ collectionId: collection }],
    };

    if (where.length > 0) {
      if (where.length === 1) {
        structuredQuery.where = { fieldFilter: this._makeFieldFilter(where[0]) };
      } else {
        structuredQuery.where = {
          compositeFilter: {
            op: 'AND',
            filters: where.map(w => ({ fieldFilter: this._makeFieldFilter(w) })),
          },
        };
      }
    }

    if (orderBy) {
      structuredQuery.orderBy = Array.isArray(orderBy) ? orderBy : [orderBy];
    }

    if (limit) {
      structuredQuery.limit = limit;
    }

    const res = await fetch(url, {
      method: 'POST',
      headers: this.headers,
      body: JSON.stringify({ structuredQuery }),
    });

    if (!res.ok) throw new Error(`query failed: ${await res.text()}`);
    
    const results = await res.json();
    return results
      .filter(r => r.document)
      .map(r => parseDoc(r.document));
  }

  /**
   * Subcollection sorgusu
   */
  async querySubcollection(parentCollection, parentDocId, subCollection, { where = [], limit } = {}) {
    const parentPath = `projects/${this.projectId}/databases/(default)/documents/${parentCollection}/${parentDocId}`;
    const url = `${BASE_URL}/${parentPath}:runQuery`;
    
    const structuredQuery = {
      from: [{ collectionId: subCollection }],
    };

    if (where.length > 0) {
      if (where.length === 1) {
        structuredQuery.where = { fieldFilter: this._makeFieldFilter(where[0]) };
      } else {
        structuredQuery.where = {
          compositeFilter: {
            op: 'AND',
            filters: where.map(w => ({ fieldFilter: this._makeFieldFilter(w) })),
          },
        };
      }
    }

    if (limit) {
      structuredQuery.limit = limit;
    }

    const res = await fetch(url, {
      method: 'POST',
      headers: this.headers,
      body: JSON.stringify({ structuredQuery }),
    });

    if (!res.ok) throw new Error(`querySubcollection failed: ${await res.text()}`);
    
    const results = await res.json();
    return results
      .filter(r => r.document)
      .map(r => parseDoc(r.document));
  }

  _makeFieldFilter({ field, op, value }) {
    const opMap = {
      '==': 'EQUAL',
      '!=': 'NOT_EQUAL',
      '<': 'LESS_THAN',
      '<=': 'LESS_THAN_OR_EQUAL',
      '>': 'GREATER_THAN',
      '>=': 'GREATER_THAN_OR_EQUAL',
      'in': 'IN',
      'array-contains': 'ARRAY_CONTAINS',
    };
    return {
      field: { fieldPath: field },
      op: opMap[op] || op,
      value: toFirestoreValue(value),
    };
  }

  /**
   * Yeni doküman ekle (auto-generated ID)
   */
  async addDoc(collection, data) {
    const url = `${this.baseUrl}/${collection}`;
    const fields = {};
    for (const [key, value] of Object.entries(data)) {
      if (value && value._delete) continue;
      const fv = toFirestoreValue(value);
      if (fv !== null) fields[key] = fv;
    }

    const res = await fetch(url, {
      method: 'POST',
      headers: this.headers,
      body: JSON.stringify({ fields }),
    });

    if (!res.ok) throw new Error(`addDoc failed: ${await res.text()}`);
    const doc = await res.json();
    const parts = doc.name.split('/');
    return parts[parts.length - 1];
  }

  /**
   * Doküman güncelle (partial update)
   */
  async updateDoc(collection, docId, data) {
    const fields = {};
    const fieldPaths = [];
    const deleteFields = [];
    
    for (const [key, value] of Object.entries(data)) {
      if (value && value._delete) {
        deleteFields.push(key);
        continue;
      }
      const fv = toFirestoreValue(value);
      if (fv !== null) {
        fields[key] = fv;
        fieldPaths.push(key);
      }
    }

    // Build update mask
    const allPaths = [...fieldPaths, ...deleteFields];
    const maskParam = allPaths.map(p => `updateMask.fieldPaths=${p}`).join('&');
    
    const url = `${this.baseUrl}/${collection}/${docId}?${maskParam}`;
    
    const res = await fetch(url, {
      method: 'PATCH',
      headers: this.headers,
      body: JSON.stringify({ fields }),
    });

    if (!res.ok) throw new Error(`updateDoc failed: ${await res.text()}`);
    return parseDoc(await res.json());
  }

  /**
   * Doküman sil
   */
  async deleteDoc(collection, docId) {
    const url = `${this.baseUrl}/${collection}/${docId}`;
    const res = await fetch(url, {
      method: 'DELETE',
      headers: this.headers,
    });
    if (!res.ok && res.status !== 404) {
      throw new Error(`deleteDoc failed: ${await res.text()}`);
    }
  }

  /**
   * Batch delete (500 limit)
   */
  async batchDelete(docs) {
    if (docs.length === 0) return;
    
    const url = `${BASE_URL}/projects/${this.projectId}/databases/(default)/documents:commit`;
    const writes = docs.map(doc => ({
      delete: typeof doc === 'string' ? doc : doc._ref,
    }));

    // Firestore batch max 500
    for (let i = 0; i < writes.length; i += 500) {
      const batch = writes.slice(i, i + 500);
      const res = await fetch(url, {
        method: 'POST',
        headers: this.headers,
        body: JSON.stringify({ writes: batch }),
      });
      if (!res.ok) throw new Error(`batchDelete failed: ${await res.text()}`);
    }
  }
}

// Sentinel values
export const serverTimestamp = () => ({ _serverTimestamp: true });
export const deleteField = () => ({ _delete: true });
