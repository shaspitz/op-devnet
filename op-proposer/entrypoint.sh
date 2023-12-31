#!/bin/bash
set -exu

MONOREPO_DIR=/shared-optimism 
DEVNET_DIR="$MONOREPO_DIR/.devnet"
ROLLUP_CONFIG_PATH="$DEVNET_DIR/rollup.json"
ADDRESSES_JSON_PATH="$DEVNET_DIR/addresses.json" # TODO: bad naming, make L1_DEPLOYMENTS_PATH TMP_L1_DEPLOYMENTS_PATH and this L1_DEPLOYMENTS_PATH

L1_GETH_URL="http://l1-geth:8545"
OP_NODE_URL="http://op-node:8545"
OP_BATCHER_URL="http://op-batcher:8545"

# Wait on op-batcher to start
while ! curl -s -X POST "${OP_BATCHER_URL}" -H "Content-type: application/json" \
    -d '{"id":1, "jsonrpc":"2.0", "method": "eth_chainId", "params":[]}' | grep -q "jsonrpc"; do
    sleep 5 # sec
done

# Obtain param generated by other container
L2_OUTPUT_ORACLE=$(jq -r '.L2OutputOracleProxy' $ADDRESSES_JSON_PATH)

exec op-proposer \
    --l2oo-address=$L2_OUTPUT_ORACLE \
    --l1-eth-rpc=$L1_GETH_URL \
    --rollup-rpc=$OP_NODE_URL \
    --poll-interval=1s \
    --num-confirmations=1 \
    --mnemonic="test test test test test test test test test test test junk" \
    --l2-output-hd-path="m/44'/60'/0'/0/1" \
    --pprof.enabled \
    --metrics.enabled \
    --allow-non-finalized \
    --rpc.enable-admin \
