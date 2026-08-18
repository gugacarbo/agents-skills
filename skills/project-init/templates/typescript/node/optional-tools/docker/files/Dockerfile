# syntax=docker/dockerfile:1

# ---------- Build stage ----------
FROM node:22-alpine AS build

WORKDIR /app

# Cache de dependências (só re-instala quando package.json/lock mudam)
COPY package.json *lock* ./
RUN corepack enable && npm ci --ignore-scripts

# Build
COPY tsconfig.json ./
COPY src ./src
RUN npm run build

# ---------- Runtime stage ----------
FROM node:22-alpine AS runtime

WORKDIR /app

ENV NODE_ENV=production

# Bundle compilado
COPY --from=build /app/dist ./dist
COPY --from=build /app/package.json ./
COPY --from=build /app/node_modules ./node_modules

# Usuário não-root (node:alpine traz o usuário `node`)
USER node

CMD ["node", "dist/index.js"]
