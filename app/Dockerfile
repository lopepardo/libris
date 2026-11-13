FROM node:26-alpine AS base
WORKDIR /app
RUN npm install -g corepack && corepack enable

# Install everything, generate the Prisma client and compile.
FROM base AS build
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./
RUN pnpm install --frozen-lockfile
COPY . .
RUN pnpm db:generate && pnpm build

# One-off task: applies migrations. Keeps the Prisma CLI (devDependency).
FROM build AS migrate
ENV NODE_ENV=production CHECKPOINT_DISABLE=1
USER node
CMD ["node_modules/.bin/prisma", "migrate", "deploy"]

# Same build, production dependencies only.
FROM build AS prod-deps
RUN pnpm prune --prod

FROM node:26-alpine AS production
WORKDIR /app
ENV NODE_ENV=production
# CA bundle so Node can verify the RDS certificate (DB_SSL=true).
ADD --chmod=644 https://truststore.pki.rds.amazonaws.com/global/global-bundle.pem /etc/ssl/certs/rds-global-bundle.pem
ENV NODE_EXTRA_CA_CERTS=/etc/ssl/certs/rds-global-bundle.pem
COPY --from=prod-deps /app/package.json ./package.json
COPY --from=prod-deps /app/node_modules ./node_modules
COPY --from=build /app/dist ./dist
USER node
EXPOSE 3000

HEALTHCHECK --interval=10s --timeout=5s --start-period=10s --retries=5 \
  CMD wget --no-verbose --tries=1 --spider "http://127.0.0.1:${PORT:-3000}/health" || exit 1

CMD ["node", "dist/main.js"]