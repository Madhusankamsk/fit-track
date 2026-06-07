FROM node:20-alpine
RUN apk add --no-cache openssl
WORKDIR /app
COPY spatial-processing-worker/package*.json ./
RUN npm ci
COPY prisma ./prisma
RUN npx prisma generate --schema=./prisma/schema.prisma
COPY spatial-processing-worker/ ./
ENV NODE_ENV=production
CMD ["node", "worker.js"]
