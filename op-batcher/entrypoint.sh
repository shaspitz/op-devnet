#!/bin/bash
set -exu

L1_GETH_URL="http://l1-geth:8545"
OP_GETH_URL="http://op-geth:8545"
OP_NODE_URL="http://op-node:8545"

# Wait on op-node to start before starting op-batcher
while ! curl -s -X POST "${OP_NODE_URL}" -H "Content-type: application/json" \
    -d '{"id":1, "jsonrpc":"2.0", "method": "eth_chainId", "params":[]}' | grep -q "jsonrpc"; do
    sleep 5 # sec
done

exec op-batcher \
    --l1-eth-rpc=$L1_GETH_URL \
    --l2-eth-rpc=$OP_GETH_URL \
    --rollup-rpc=$OP_NODE_URL \
    --max-channel-duration=1 \
    --sub-safety-margin=4 \
    --poll-interval=1s \
    --num-confirmations=1 \
    --safe-abort-nonce-too-low-count=3 \
    --resubmission-timeout=30s \
    --rpc.addr=0.0.0.0 \
    --rpc.port=8548 \
    --rpc.enable-admin \
    --private-key=8b3a350cf5c34c9194ca85829a2df0ec3153be0318b5e2d3348e872092edffba
