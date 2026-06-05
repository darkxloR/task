FROM node:24.16.0

WORKDIR /app

COPY package*.json ./

COPY index.js ./

RUN npm install

EXPOSE 3001

ENTRYPOINT ["npm", "start"]


