# The game server, with the exported web game in server/public. Mount a volume at /data to keep accounts.
FROM node:24-slim
WORKDIR /app
COPY server/package.json server/package-lock.json ./
RUN npm ci --omit=dev
COPY server/server.js ./
COPY server/public ./public
ENV PORT=8787 DB_PATH=/data/game.db
EXPOSE 8787
CMD ["node", "server.js"]
