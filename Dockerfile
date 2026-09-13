FROM node:20-alpine

WORKDIR /app

# Install deps first so this layer is cached unless package*.json changes
COPY package.json package-lock.json ./
RUN npm ci --omit=dev

COPY server.js ./
COPY public ./public

# rois.json, exclusions.json, settings.json, alerts_history.json,
# detections_state.json, and .env are intentionally NOT copied in — they're
# runtime state / secrets, bind-mounted at run time instead (see
# docker-compose.yml). This image is code only.

EXPOSE 3010

CMD ["node", "server.js"]
