#!/bin/sh
# Backend entrypoint. Preload the New Relic agent the PROVEN way — `node -r newrelic`
# loads it before any app module, so it can instrument them. An in-app require()/import
# runs too late and misses instrumentation. Dormant by design: plain `node` with no key.
if [ -n "$NEW_RELIC_LICENSE_KEY" ]; then
  exec node -r newrelic services/backend/dist/main.js
else
  exec node services/backend/dist/main.js
fi
