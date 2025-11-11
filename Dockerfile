FROM node:20-slim

WORKDIR /usr/src/app

COPY package*.json ./
RUN npm ci --only=production
COPY . .

RUN mkdir -p /var/logs/crud

EXPOSE 8080

CMD ["node", "index.js"]
