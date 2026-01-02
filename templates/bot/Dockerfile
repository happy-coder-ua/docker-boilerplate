FROM node:lts-alpine

WORKDIR /app

ENV NODE_ENV=production

COPY package.json package-lock.json* ./

RUN if [ -f package-lock.json ]; then npm ci --omit=dev; else npm install --omit=dev; fi

COPY . .

CMD ["npm", "start"]
