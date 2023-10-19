FROM node:lts-alpine

WORKDIR /app

RUN npm init -y
RUN npm install --save-dev hardhat

COPY hardhat.config.js ./hardhat.config.js

EXPOSE 8545

CMD ["npx", "hardhat", "node"]
