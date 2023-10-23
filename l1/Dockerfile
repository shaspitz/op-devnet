# Foundry docker image ref based on alpine
FROM ghcr.io/foundry-rs/foundry:latest

WORKDIR /

# Install deps, # TODO: consolidate these 
RUN apk update && \
    apk add --no-cache git curl jq make bash nodejs npm direnv openssl
RUN npm install -g pnpm

# Go install and update path
RUN wget https://golang.org/dl/go1.20.linux-amd64.tar.gz
RUN tar -C /usr/local -xzf go1.20.linux-amd64.tar.gz
ENV PATH="/usr/local/go/bin:${PATH}"

RUN git clone --recurse-submodules https://github.com/ethereum-optimism/optimism.git
WORKDIR /optimism
RUN git checkout v1.2.0
RUN pnpm install 
RUN make op-node op-batcher op-proposer
RUN pnpm build

ENV GOPATH /go
RUN make pre-devnet
ENV PATH $PATH:$GOPATH/bin

# Copy host deploy config to tmp location
COPY deploy-config/primev-settlement.json /tmp/deploy-config/primev-settlement.json

EXPOSE 8545

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
