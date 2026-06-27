# Multi-stage. Build context is the REPO ROOT (workspace deps live there).
# Production ships only compiled dist/ + backend prod deps. Prisma 7 emits a TS
# client into src/generated/prisma, so it compiles into dist — nothing to copy
# from node_modules.
FROM node:22-alpine AS build
WORKDIR /app
COPY package.json package-lock.json ./
COPY services/frontend/package.json services/frontend/
COPY services/backend/package.json services/backend/
RUN npm ci --ignore-scripts
COPY . .
RUN cd services/backend && npx prisma generate   # TS client → src/generated/prisma
RUN npm run build --workspace services/backend    # compiles app + client into dist

FROM node:22-alpine AS runner
WORKDIR /app
ENV NODE_ENV=production
COPY package.json package-lock.json ./
COPY services/backend/package.json services/backend/
RUN npm ci --omit=dev --ignore-scripts --workspace services/backend
COPY --from=build /app/services/backend/dist ./services/backend/dist
COPY --from=build /app/services/backend/newrelic.js ./services/backend/newrelic.js
COPY --from=build /app/services/backend/start.sh ./services/backend/start.sh
ENV NEW_RELIC_HOME=/app/services/backend
EXPOSE 3000
# start.sh preloads New Relic via `node -r newrelic` when a key is set (the proven way).
CMD ["sh", "services/backend/start.sh"]
