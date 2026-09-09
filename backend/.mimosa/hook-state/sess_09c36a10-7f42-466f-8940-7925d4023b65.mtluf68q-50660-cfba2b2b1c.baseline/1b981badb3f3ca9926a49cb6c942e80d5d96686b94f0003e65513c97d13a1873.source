const config = require('../config');

describe('resolveMetrics strategies + stale counter', () => {
  const {
    recordStrategy,
    recordStaleServed,
    getMetrics,
    resetMetrics,
  } = require('./resolveMetrics');

  afterEach(() => {
    config.nodeEnv = 'test';
    resetMetrics();
  });

  test('recordStrategy aggregates attempts/successes with rate', () => {
    config.nodeEnv = 'development';
    recordStrategy('html', true);
    recordStrategy('html', true);
    recordStrategy('html', false);
    recordStrategy('spare', false);
    const m = getMetrics();
    expect(m.strategies.html).toEqual({ attempts: 3, successes: 2, successRate: 66.7 });
    expect(m.strategies.spare).toEqual({ attempts: 1, successes: 0, successRate: 0 });
    expect(m.strategies.__missing__).toBeUndefined();
  });

  test('recordStaleServed counts and resets', () => {
    config.nodeEnv = 'development';
    recordStaleServed();
    recordStaleServed();
    expect(getMetrics().staleServed).toBe(2);
    resetMetrics();
    expect(getMetrics().staleServed).toBe(0);
  });

  test('noop in test env', () => {
    recordStrategy('html', true);
    recordStaleServed();
    const m = getMetrics();
    expect(m.strategies).toEqual({});
    expect(m.staleServed).toBe(0);
  });
});
