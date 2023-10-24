#!/bin/sh

# Based off https://github.com/ethereum-optimism/optimism/tree/develop/bedrock-devnet
# with consistency to mev-commit docker/shell setup.

# TODO: change devnetL1 to primev string, use custom deploy config
# TODO: possibly clean up naming
MONOREPO_DIR=/shared-optimism 
DEVNET_DIR="$MONOREPO_DIR/.devnet"
CONTRACTS_BEDROCK_DIR="$MONOREPO_DIR/packages/contracts-bedrock"
DEPLOYMENT_DIR="$CONTRACTS_BEDROCK_DIR/deployments/devnetL1"
OP_NODE_DIR="$MONOREPO_DIR/op-node"
OPS_BEDROCK_DIR="$MONOREPO_DIR/ops-bedrock"
DEPLOY_CONFIG_DIR="$CONTRACTS_BEDROCK_DIR/deploy-config"
DEVNET_CONFIG_PATH="$DEPLOY_CONFIG_DIR/devnetL1.json"
DEVNET_CONFIG_TEMPLATE_PATH="$DEPLOY_CONFIG_DIR/devnetL1-template.json"
OPS_CHAIN_OPS="$MONOREPO_DIR/op-chain-ops"
SDK_DIR="$MONOREPO_DIR/packages/sdk"

# TODO: rm unused
L1_DEPLOYMENTS_PATH="$DEPLOYMENT_DIR/.deploy"
GENESIS_L1_PATH="$DEVNET_DIR/genesis-l1.json"
GENESIS_L2_PATH="$DEVNET_DIR/genesis-l2.json"
ALLOCS_PATH="$DEVNET_DIR/allocs-l1.json"
ADDRESSES_JSON_PATH="$DEVNET_DIR/addresses.json" # TODO: bad naming, make L1_DEPLOYMENTS_PATH TMP_L1_DEPLOYMENTS_PATH and this L1_DEPLOYMENTS_PATH 
SDK_ADDRESSES_JSON_PATH="$DEVNET_DIR/sdk-addresses.json"
ROLLUP_CONFIG_PATH="$DEVNET_DIR/rollup.json"

GETH_URL='http://localhost:8545' 

mkdir -p "$DEVNET_DIR"

echo Starting devnet setup...

if [ ! -e "$GENESIS_L1_PATH" ]; then
    echo "Generating genesis-l1.json"

    if [ ! -e "$ALLOCS_PATH" ]; then
        echo "Generating allocs-l1.json"
        cat "$DEVNET_CONFIG_TEMPLATE_PATH" > "$DEVNET_CONFIG_PATH"
        # TODO: mutations could happen here

        # Spawn ephemeral geth in dev mode to deploy L1 contracts into state
        geth --dev --http --http.api eth,debug \
            --verbosity 4 --gcmode archive --dev.gaslimit 30000000 \
            --rpc.allow-unprotected-txs & # Note & denoting background process

        # Capture PID of process we just started 
        GETH_PID=$!

        # Wait for ephemeral geth to start up
        COUNTER=0
        RETRIES=10
        while [[ $COUNTER -lt $RETRIES ]]; do
            echo "$(date '+%Y-%m-%d %H:%M:%S') - Trying to connect to RPC server at ${GETH_URL}"
            if curl -s -X POST "${GETH_URL}" -H "Content-type: application/json" \
            -d '{"id":1, "jsonrpc":"2.0", "method": "eth_chainId", "params":[]}' | grep -q "jsonrpc"; then
                echo "$(date '+%Y-%m-%d %H:%M:%S') - RPC server at ${GETH_URL} ready"
                break
            fi
            sleep 1 # sec 
            COUNTER=$((COUNTER + 1))
        done
        if [[ $COUNTER -eq $RETRIES ]]; then
            echo "$(date '+%Y-%m-%d %H:%M:%S') - Timed out waiting for RPC server at ${GETH_URL}."
            exit 1
        fi

        # Fetch eth_accounts
        DATA=$(curl -s -X POST "${GETH_URL}" -H "Content-type: application/json" \
            -d '{"id":2, "jsonrpc":"2.0", "method": "eth_accounts", "params":[]}')
        ACCOUNT=$(echo "$DATA" | jq -r '.result[0]')
        echo "$(date '+%Y-%m-%d %H:%M:%S') - Deploying with $ACCOUNT"

        cd "$CONTRACTS_BEDROCK_DIR"

        # Send ETH to create2 deployer account, then deploy
        cast send --from "$ACCOUNT" \
            --rpc-url "$GETH_URL" \
            --unlocked \
            --value '1ether' \
            0x3fAB184622Dc19b6109349B94811493BF2a45362 
        echo "publishing raw tx for create2 deployer"
        cast publish --rpc-url "$GETH_URL" \
            '0xf8a58085174876e800830186a08080b853604580600e600039806000f350fe7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe03601600081602082378035828234f58015156039578182fd5b8082525050506014600cf31ba02222222222222222222222222222222222222222222222222222222222222222a02222222222222222222222222222222222222222222222222222222222222222' \

        echo "Deploying L1 contracts"
        forge script scripts/Deploy.s.sol:Deploy --sender $ACCOUNT --broadcast --rpc-url $GETH_URL --unlocked

        # Copy .deploy artifact before sync
        cp $L1_DEPLOYMENTS_PATH $ADDRESSES_JSON_PATH 

        echo "Syncing L1 contracts"
        forge script scripts/Deploy.s.sol:Deploy --sig 'sync()' --broadcast --rpc-url $GETH_URL

        # Send debug_dumpBlock request to geth, save res to allocs.json
        BODY='{"id":3, "jsonrpc":"2.0", "method": "debug_dumpBlock", "params":["latest"]}'
        curl -s -X POST \
            -H "Content-type: application/json" \
            -d "${BODY}" \
            "${GETH_URL}" | jq -r '.result' > $ALLOCS_PATH

        # Kill ephemmeral geth in dev mode, we need to mutate l1 genesis and start again
        kill $GETH_PID
    else
        echo "allocs-l1.json already exist"
    fi

    # TODO: skipping init devnet l1 depoly config with updated timestamp

    cd $OP_NODE_DIR
    # Create l1 genesis 
    go run cmd/main.go genesis l1 \
        --deploy-config $DEVNET_CONFIG_PATH \
        --l1-allocs $ALLOCS_PATH \
        --l1-deployments $ADDRESSES_JSON_PATH \
        --outfile.l1 $GENESIS_L1_PATH
else 
    echo "genesis-l1.json already exist"
fi    

# Signal L1 to start
touch /shared-optimism/start_l1
echo "signaled L1 to start"
while true; do
    sleep 10  
done

if [ ! -e "$GENESIS_L2_PATH" ]; then
    echo "Generating genesis-l2.json and rollup.json"
    cd $OP_NODE_DIR
    go run cmd/main.go genesis l2 \
        --l1-rpc $GETH_URL \
        --deploy-config $DEVNET_CONFIG_PATH \
        --deployments-dir $DEPLOYMENT_DIR \
        --outfile.l2 $GENESIS_L2_PATH \
        --outfile.rollup $ROLLUP_CONFIG_PATH
else 
    echo "genesis-l2.json and rollup.json already exist"
fi

# TODO: separate signal for l2 possible?

while true; do
    sleep 10  
done
