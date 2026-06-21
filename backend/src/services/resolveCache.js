const config = require('../config');

/**
 * In-memory LRU resolve cache (URL → response).
 */
class ResolveCache {
  constructor(maxEntries = config.cacheMaxEntries, ttlMs = config.cacheTtlMs) {
    this.maxEntries = maxEntries;
    this.ttlMs = ttlMs;
    this.store = new Map();
  }

  _key(url) {
    return url.trim().toLowerCase();
  }

  get(url) {
    const key = this._key(url);
    const entry = this.store.get(key);
    if (!entry) return null;
    if (Date.now() > entry.expiresAt) {
      this.store.delete(key);
      return null;
    }
    // LRU touch
    this.store.delete(key);
    this.store.set(key, entry);
    return entry.value;
  }

  set(url, value) {
    if (!value || value.ok !== true) return;
    const key = this._key(url);
    if (this.store.has(key)) this.store.delete(key);
    while (this.store.size >= this.maxEntries) {
      const oldest = this.store.keys().next().value;
      this.store.delete(oldest);
    }
    this.store.set(key, {
      value,
      expiresAt: Date.now() + this.ttlMs,
    });
  }

  clear() {
    this.store.clear();
  }

  get stats() {
    return { size: this.store.size, maxEntries: this.maxEntries };
  }
}

/**
 * L1 in-memory + optional L2 Redis for multi-instance deployments.
 */
class CompositeResolveCache {
  constructor() {
    this.memory = new ResolveCache();
    this.redis = null;
    this.ttlSec = Math.max(1, Math.floor(config.cacheTtlMs / 1000));
    this.prefix = 'resolve:';
  }

  attachRedis(client) {
    if (!config.cacheRedisEnabled) return;
    this.redis = client;
  }

  _redisKey(url) {
    return `${this.prefix}${url.trim().toLowerCase()}`;
  }

  async get(url) {
    const mem = this.memory.get(url);
    if (mem) return mem;
    if (!this.redis?.isReady) return null;
    try {
      const raw = await this.redis.get(this._redisKey(url));
      if (!raw) return null;
      const value = JSON.parse(raw);
      if (!value || value.ok !== true) return null;
      this.memory.set(url, value);
      return value;
    } catch {
      return null;
    }
  }

  set(url, value) {
    this.memory.set(url, value);
    if (!this.redis?.isReady || !value || value.ok !== true) return;
    this.redis
      .setEx(this._redisKey(url), this.ttlSec, JSON.stringify(value))
      .catch(() => {});
  }

  clear() {
    this.memory.clear();
  }

  get stats() {
    return {
      ...this.memory.stats,
      redis: Boolean(this.redis?.isReady),
    };
  }
}

const resolveCache = new CompositeResolveCache();

module.exports = { ResolveCache, CompositeResolveCache, resolveCache };
