FROM node:20-alpine
RUN apk add --no-cache openssl
WORKDIR /app
COPY auth-user-service/package*.json ./
RUN npm ci
COPY prisma ./prisma
RUN npx prisma generate --schema=./prisma/schema.prisma
COPY auth-user-service/ ./
ENV NODE_ENV=production
EXPOSE 5001
CMD ["node", "server.js"]
