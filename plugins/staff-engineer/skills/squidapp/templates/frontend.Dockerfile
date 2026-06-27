# Multi-stage. Build context is the REPO ROOT (workspace deps live there).
# Production image ships only Next's standalone compiled output — no source, no dev deps.
FROM node:22-alpine AS build
WORKDIR /app
COPY package.json package-lock.json ./
COPY services/frontend/package.json services/frontend/
COPY services/backend/package.json services/backend/
RUN npm ci --ignore-scripts
COPY . .
ARG NEXT_PUBLIC_API_URL
ENV NEXT_PUBLIC_API_URL=$NEXT_PUBLIC_API_URL
RUN npm run build --workspace services/frontend

FROM node:22-alpine AS runner
WORKDIR /app
ENV NODE_ENV=production
COPY --from=build /app/services/frontend/.next/standalone ./
COPY --from=build /app/services/frontend/.next/static ./services/frontend/.next/static
COPY --from=build /app/services/frontend/public ./services/frontend/public
EXPOSE 3000
CMD ["node", "services/frontend/server.js"]
