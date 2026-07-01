/**
 * HTTP client for Instagram upstream with public DNS bypass.
 * Fixes ENOTFOUND when router DNS (e.g. OpenWrt) blocks instagram.com.
 */

const https = require('https');
const http = require('http');
const dns = require('dns');
const axios = require('axios');
const config = require('../config');

const PUBLIC_DNS = (config.instagramDnsServers || '8.8.8.8,1.1.1.1,8.8.4.4')
  .split(',')
  .map((s) => s.trim())
  .filter(Boolean);

if (PUBLIC_DNS.length > 0 && config.usePublicDnsForInstagram !== false) {
  dns.setServers(PUBLIC_DNS);
}

function dnsLookup(hostname, options, callback) {
  if (typeof options === 'function') {
    callback = options;
    options = {};
  }

  const finish = (err, addresses, fam) => {
    if (err) {
      callback(err);
      return;
    }
    if (!addresses || addresses.length === 0) {
      callback(new Error(`No DNS addresses for ${hostname}`));
      return;
    }
    if (options.all) {
      callback(
        null,
        addresses.map((address) => ({ address, family: fam })),
      );
      return;
    }
    callback(null, addresses[0], fam);
  };

  const family = options.family;
  if (family === 6) {
    dns.resolve6(hostname, (err, addresses) => finish(err, addresses, 6));
    return;
  }
  if (family === 4) {
    dns.resolve4(hostname, (err, addresses) => finish(err, addresses, 4));
    return;
  }

  dns.resolve4(hostname, (err4, addresses4) => {
    if (!err4 && addresses4?.length) {
      finish(null, addresses4, 4);
      return;
    }
    dns.resolve6(hostname, (err6, addresses6) => {
      if (err6) {
        callback(err4 || err6);
        return;
      }
      finish(null, addresses6, 6);
    });
  });
}

const httpsAgent = new https.Agent({ lookup: dnsLookup, keepAlive: true });
const httpAgent = new http.Agent({ lookup: dnsLookup, keepAlive: true });

function mergeConfig(extra = {}) {
  if (process.env.NODE_ENV === 'test') {
    return extra;
  }
  return {
    ...extra,
    httpAgent,
    httpsAgent,
  };
}

function get(url, config) {
  return axios.get(url, mergeConfig(config));
}

function post(url, data, config) {
  return axios.post(url, data, mergeConfig(config));
}

function head(url, config) {
  return axios.head(url, mergeConfig(config));
}

module.exports = {
  get,
  post,
  head,
  mergeConfig,
};
