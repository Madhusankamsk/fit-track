FROM node:20-alpine
RUN apk add --no-cache openssl
WORKDIR /app
COPY activity-ingestion-api/package*.json ./
RUN npm ci
COPY prisma ./prisma
RUN npx prisma generate --schema=./prisma/schema.prisma
COPY activity-ingestion-api/ ./
ENV NODE_ENV=production
EXPOSE 5002
CMD ["node", "server.js"]
