# Get NPM packages
FROM node:16-alpine AS dependencies
RUN apk add --no-cache libc6-compat
RUN npm i -g pnpm
WORKDIR /app
COPY package.json pnpm-lock.yaml ./
RUN pnpm i
# Rebuild the source code only when needed
FROM node:16-alpine AS builder
RUN npm i -g pnpm
WORKDIR /app
COPY . .
COPY --from=dependencies /app/node_modules ./node_modules
RUN pnpm build

# Production image, copy all the files and run next
FROM node:16-alpine AS runner
WORKDIR /app

ENV NODE_ENV production

RUN addgroup -g 1001 -S app
RUN adduser -S app -u 1001

COPY --from=builder --chown=app:app /app/.next ./.next
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package.json ./package.json

USER app
EXPOSE 3000

CMD ["npm", "start"]
