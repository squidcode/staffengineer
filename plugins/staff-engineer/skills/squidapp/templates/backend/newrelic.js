'use strict';
/**
 * New Relic agent config. The agent is preloaded via `node -r newrelic` in start.sh
 * (only when NEW_RELIC_LICENSE_KEY is set), so this is inert until that env var arrives.
 * Every value is overridable via NEW_RELIC_* env vars.
 */
exports.config = {
  app_name: [process.env.NEW_RELIC_APP_NAME || '__APP_NAME__-backend'],
  license_key: process.env.NEW_RELIC_LICENSE_KEY,
  distributed_tracing: { enabled: true },
  application_logging: {
    enabled: true,
    forwarding: { enabled: true }, // ship debug/info/error logs to NR Logs
    metrics: { enabled: true },
  },
  logging: { level: 'info' },
  // Don't capture all headers — keep auth/cookie/proxy creds out of NR.
  attributes: {
    exclude: [
      'request.headers.authorization',
      'request.headers.cookie',
      'request.headers.proxyAuthorization',
      'request.headers.setCookie*',
      'request.headers.x-*',
    ],
  },
};
