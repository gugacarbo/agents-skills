# syntax=docker/dockerfile:1

# ---------- Build stage ----------
FROM node:22-alpine AS build

WORKDIR /app

COPY package.json *lock* ./
RUN corepack enable && npm ci --ignore-scripts

COPY . .
RUN npm run build

# ---------- Runtime stage (estático) ----------
FROM nginx:1.27-alpine AS runtime

# Serve o output estático do Vite (dist/)
COPY --from=build /app/dist /usr/share/nginx/html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
