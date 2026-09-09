jest.mock('../config', () => ({
  nodeEnv: 'production',
}));

const { recordResolve, getMetrics, resetMetrics } = require('./resolveMetrics');

describe('resolveMetrics', () => {
  beforeEach(() => {
    resetMetrics();
  });

  test('empty metrics default to 100% success rate', () => {
    const m = getMetrics();
    expect(m.total).toBe(0);
    expect(m.successRate).toBe(100);
    expect(m.alert).toBe(false);
  });

  test('records success and failure counts', () => {
    recordResolve({ ok: true });
    recordResolve({ ok: true });
    recordResolve({ ok: false, error: 'not_found' });
    const m = getMetrics();
    expect(m.total).toBe(3);
    expect(m.success).toBe(2);
    expect(m.failures.not_found).toBe(1);
    expect(m.failureTotal).toBe(1);
  });

  test('alert when success rate drops below 70% with enough samples', () => {
    for (let i = 0; i < 15; i += 1) {
      recordResolve({ ok: true });
    }
    for (let i = 0; i < 10; i += 1) {
      recordResolve({ ok: false, error: 'resolver_failed' });
    }
    const m = getMetrics();
    expect(m.total).toBe(25);
    expect(m.successRate).toBeLessThan(70);
    expect(m.alert).toBe(true);
  });
});
