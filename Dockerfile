FROM node:alpine
WORKDIR /usr/src/app
COPY package.json /usr/src/app/
COPY . /usr/src/app/

RUN npm install --production
EXPOSE 8081
ENTRYPOINT ["npm", "start"]