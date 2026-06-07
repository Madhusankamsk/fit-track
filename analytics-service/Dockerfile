FROM node:20-alpine
WORKDIR /app
COPY analytics-service/package*.json ./
RUN npm ci --only=production
COPY prisma ./prisma
RUN npx prisma generate --schema=./prisma/schema.prisma
COPY analytics-service/ ./
ENV NODE_ENV=production
EXPOSE 5003
CMD ["node", "server.js"]
