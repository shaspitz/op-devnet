#!/bin/sh

cat hardhat.config.js

sed -i "s|\"NULL_URL\"|\"$L1_SYNC_URL\"|" hardhat.config.js

cat hardhat.config.js

echo $L1_SYNC_URL

npx hardhat node