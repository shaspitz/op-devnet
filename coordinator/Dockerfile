FROM golang:1.21-bullseye

WORKDIR /

# Install deps
RUN apt-get update && \
    apt-get install -y git curl jq make bash openssl python3 build-essential ca-certificates

# Upgrade Node.js to a newer version
RUN curl -fsSL https://deb.nodesource.com/setup_16.x | bash - && \
    apt-get install -y nodejs

ENV PYTHON python3

RUN npm install -g pnpm

RUN curl -L https://foundry.paradigm.xyz | bash
ENV PATH="${PATH}:/root/.foundry/bin"
RUN foundryup

WORKDIR /shared-optimism
RUN git clone --recurse-submodules https://github.com/ethereum-optimism/optimism.git .
RUN git checkout v1.2.0
RUN pnpm install 
RUN make op-node op-batcher op-proposer
RUN pnpm build

ENV GOPATH /go
RUN make pre-devnet

ENV PATH $PATH:$GOPATH/bin

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
