const dns = require('dns');

describe('instagramHttp DNS', () => {
  test('resolves instagram.com via public DNS', (done) => {
    dns.setServers(['8.8.8.8', '1.1.1.1']);
    dns.resolve4('www.instagram.com', (err, addresses) => {
      expect(err).toBeNull();
      expect(addresses.length).toBeGreaterThan(0);
      done();
    });
  });
});
