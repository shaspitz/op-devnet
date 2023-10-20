# TODO: split into multiple dockerfiles and optimize build, use volumes

# Foundry docker image ref based on alpine
FROM ghcr.io/foundry-rs/foundry:latest

# Install deps
RUN apk update && \
    apk add --no-cache git curl jq make bash nodejs npm direnv
RUN npm install -g pnpm

# Go install and update path
RUN wget https://golang.org/dl/go1.20.linux-amd64.tar.gz
RUN tar -C /usr/local -xzf go1.20.linux-amd64.tar.gz
ENV PATH="/usr/local/go/bin:${PATH}"

# Install op-stack monorepo and build op-node, op-batcher, op-proposer
RUN git clone --recurse-submodules https://github.com/ethereum-optimism/optimism.git
WORKDIR /optimism
RUN pnpm install && make op-node op-batcher op-proposer && pnpm build

# Install and build op-geth
WORKDIR /
RUN git clone https://github.com/ethereum-optimism/op-geth.git
WORKDIR /op-geth
RUN make geth

# Copy host deploy config to tmp location
# Note if dockerfiles are split, this could be removed from all but the coordinator build
COPY deploy-config/primev-settlement.json /tmp/deploy-config/primev-settlement.json

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

# Try to query L1 node for block num
# RUN curl -X POST --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' http://l1:8545
