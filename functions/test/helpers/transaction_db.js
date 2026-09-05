// Optimistic transaction test double. No SDK/network or production credentials.
import assert from 'node:assert/strict';
const clone = value => structuredClone(value);
const conflict = () => Object.assign(new Error('Transaction conflict'), { code: 409 });

export function withTransactions(db) {
  let serial = 0;
  let commitTail = Promise.resolve();
  const transactions = new Map();
  const read = db.getDocument.bind(db);
  const update = db.updateDocument.bind(db);
  const key = o => `${o.databaseId}/${o.collectionId}/${o.documentId}`;
  return new Proxy(db, {
    get(target, name) {
      if (name === 'transactions') return transactions;
      if (name === 'createTransaction') return async ({ ttl }) => {
        assert.equal(ttl, 15);
        const id = `tx_${++serial}`;
        transactions.set(id, { reads: new Map(), writes: new Map() });
        return { $id: id };
      };
      if (name === 'getDocument') return async (...args) => {
        if (typeof args[0] !== 'object') return read(...args);
        const o = args[0];
        const tx = transactions.get(o.transactionId);
        assert.ok(tx, 'transaction exists');
        if (!tx.reads.has(key(o))) {
          tx.reads.set(key(o), { options: o, value: clone(await read(o.databaseId, o.collectionId, o.documentId)) });
        }
        return clone(tx.writes.get(key(o))?.value || tx.reads.get(key(o)).value);
      };
      if (name === 'updateDocument') return async (...args) => {
        if (typeof args[0] !== 'object') return update(...args);
        const o = args[0];
        const tx = transactions.get(o.transactionId);
        assert.ok(tx?.reads.has(key(o)), 'transaction must read before writing');
        const value = { ...tx.reads.get(key(o)).value, ...clone(o.data) };
        tx.writes.set(key(o), { options: o, value });
        return clone(value);
      };
      if (name === 'updateTransaction') return async ({ transactionId, commit, rollback }) => {
        const tx = transactions.get(transactionId);
        assert.ok(tx, 'transaction exists');
        if (commit) {
          const commitWork = commitTail.then(async () => {
            if (target.beforeCommit) await target.beforeCommit();
            if (target.failCommit) throw Object.assign(new Error('Commit unavailable'), { code: 503 });
            for (const { options: o, value } of tx.reads.values()) {
              if (JSON.stringify(await read(o.databaseId, o.collectionId, o.documentId)) !== JSON.stringify(value)) throw conflict();
            }
            for (const { options: o } of tx.writes.values()) {
              await update(o.databaseId, o.collectionId, o.documentId, o.data, o.permissions);
            }
          });
          commitTail = commitWork.catch(() => {});
          await commitWork;
        }
        if (commit || rollback) transactions.delete(transactionId);
        return {};
      };
      const value = target[name];
      return typeof value === 'function' ? value.bind(target) : value;
    },
  });
}

export class MemoryDatabase {
  constructor(purchase) {
    this.docs = new Map(purchase ? [['course_purchases/purchase', { $id: 'purchase', ...purchase }]] : []);
    this.writes = [];
  }
  async getDocument(_, collection, id) {
    const doc = this.docs.get(`${collection}/${id}`);
    if (!doc) throw Object.assign(new Error('Missing document'), { code: 404 });
    return clone(doc);
  }
  async listDocuments(_, collection) {
    return { documents: [...this.docs].filter(([key]) => key.startsWith(`${collection}/`)).map(([, doc]) => clone(doc)) };
  }
  async createDocument(_, collection, id, data) {
    const key = `${collection}/${id}`;
    if (this.docs.has(key)) throw conflict();
    const result = { $id: id, ...clone(data) };
    this.docs.set(key, result);
    this.writes.push({ collection, id, data: clone(data) });
    return clone(result);
  }
  async updateDocument(_, collection, id, data, permissions) {
    const key = `${collection}/${id}`;
    const old = this.docs.get(key);
    if (!old) throw Object.assign(new Error('Missing document'), { code: 404 });
    const result = { ...old, ...clone(data) };
    this.docs.set(key, result);
    this.writes.push({ collection, id, data: clone(data), permissions });
    return clone(result);
  }
}
