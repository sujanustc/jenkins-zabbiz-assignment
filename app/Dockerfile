FROM node:18-alpine

WORKDIR /usr/src/app

COPY package*.json ./

RUN npm install --omit=dev

COPY index.js ./

EXPOSE 3000

ENV PORT=3000

CMD [ "npm", "start" ]
