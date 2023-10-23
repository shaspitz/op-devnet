#!/bin/sh

# cp monorepo to shared volume
cp -r /optimism/* /shared-optimism

# Copy deploy config from tmp location to shared volume loc
DEPLOY_CONFIG_PATH="/shared-optimism/packages/contracts-bedrock/deploy-config/primev-settlement.json"
cp /tmp/deploy-config/primev-settlement.json $DEPLOY_CONFIG_PATH 

# Spawn ephemeral geth in dev mode to deploy contract
geth --dev --http --http.api eth,debug \
     --verbosity 4 --gcmode archive --dev.gaslimit 30000000 \
     --rpc.allow-unprotected-txs & # Note & denoting background process

# Capture PID of process we just started 
GETH_PID=$!

echo "will connect to L1 ETH_RPC_URL at: $GETH_URL"

RETRIES=10

COUNTER=0
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

# Check our custom deploy config for breaking changes
cd /shared-optimism
go run op-chain-ops/cmd/check-deploy-config/main.go --path $DEPLOY_CONFIG_PATH

cd /shared-optimism/packages/contracts-bedrock

# Create deployments dir
mkdir -p deployments/primev-settlement

# Fetch eth_accounts
DATA=$(curl -s -X POST "${GETH_URL}" -H "Content-type: application/json" \
    -d '{"id":2, "jsonrpc":"2.0", "method": "eth_accounts", "params":[]}')
ACCOUNT=$(echo "$DATA" | jq -r '.result[0]')
echo "$(date '+%Y-%m-%d %H:%M:%S') - Deploying with $ACCOUNT"

# Send ETH to create2 deployer account, then deploy
cast send --from "$ACCOUNT" \
     --rpc-url "$GETH_URL" \
     --unlocked \
     --value 1ether \
     0x3fAB184622Dc19b6109349B94811493BF2a45362 \
    #  --cwd "$CONTRACTS_BEDROCK_DIR"
cast publish --rpc-url "$GETH_URL" \
     '0xf8a58085174876e800830186a08080b853604580600e600039806000f350fe7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe03601600081602082378035828234f58015156039578182fd5b8082525050506014600cf31ba02222222222222222222222222222222222222222222222222222222222222222a02222222222222222222222222222222222222222222222222222222222222222' \
    #  --cwd "$CONTRACTS_BEDROCK_DIR"

# Deploy and sync OP L1 contracts
forge script scripts/Deploy.s.sol:Deploy --sender $ACCOUNT --broadcast --rpc-url $GETH_URL --unlocked

# save .deploy artifact before sync
cp /shared-optimism/packages/contracts-bedrock/deployments/primev-settlement/.deploy /.deploy

forge script scripts/Deploy.s.sol:Deploy --sig 'sync()' --private-key $PRIVATE_KEY --broadcast --rpc-url $GETH_URL

# Send debug_dumpBlock request to geth, save res to /allocs.json
BODY='{"id":3, "jsonrpc":"2.0", "method": "debug_dumpBlock", "params":["latest"]}'
curl -s -X POST \
     -H "Content-type: application/json" \
     -d "${BODY}" \
     "${GETH_URL}" | jq -r '.result' > /allocs.json

# Kill ephemmeral geth in dev mode, we need to mutate l1 genesis and start again
kill $GETH_PID

cd /shared-optimism/op-node

# Create l1 genesis 
go run cmd/main.go genesis l1 \
    --deploy-config $DEPLOY_CONFIG_PATH \
    --l1-allocs /allocs.json \
    --l1-deployments /.deploy \
    --outfile.l1 /genesis-l1.json

# Setup for geth instance (no longer in dev mode, but still POA)
GETH_DATA_DIR=/db
mkdir /db
GETH_CHAINDATA_DIR="$GETH_DATA_DIR/geth/chaindata"
GETH_KEYSTORE_DIR="$GETH_DATA_DIR/keystore"
GENESIS_FILE_PATH="/genesis-l1.json"
CHAIN_ID=$(cat "$GENESIS_FILE_PATH" | jq -r .config.chainId)
BLOCK_SIGNER_PRIVATE_KEY="ac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"
BLOCK_SIGNER_ADDRESS="0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"

# Import key into geth keystore
echo -n "pwd" > "$GETH_DATA_DIR"/password
echo -n "$BLOCK_SIGNER_PRIVATE_KEY" | sed 's/0x//' > "$GETH_DATA_DIR"/block-signer-key
geth account import \
     --datadir="$GETH_DATA_DIR" \
     --password="$GETH_DATA_DIR"/password \
     "$GETH_DATA_DIR"/block-signer-key

# Init genesis
geth --verbosity=3 init \
     --datadir="$GETH_DATA_DIR" \
     "$GENESIS_FILE_PATH"

echo "Starting geth with chain id $CHAIN_ID"

exec geth \
	--datadir="$GETH_DATA_DIR" \
	--verbosity=3 \
	--http \
	--http.corsdomain="*" \
	--http.vhosts="*" \
	--http.addr=0.0.0.0 \
	--http.port=8545 \
	--http.api=web3,debug,eth,txpool,net,engine \
	--ws \
	--ws.addr=0.0.0.0 \
	--ws.port=8546 \
	--ws.origins="*" \
	--ws.api=debug,eth,txpool,net,engine \
	--syncmode=full \
	--nodiscover \
	--maxpeers=1 \
	--networkid=$CHAIN_ID \
	--unlock=$BLOCK_SIGNER_ADDRESS \
	--mine \
	--miner.etherbase=$BLOCK_SIGNER_ADDRESS \
	--password="$GETH_DATA_DIR"/password \
	--allow-insecure-unlock \
	--rpc.allow-unprotected-txs \
	--authrpc.addr="0.0.0.0" \
	--authrpc.port="8551" \
	--authrpc.vhosts="*" \
	--gcmode=archive \
	--metrics \
	--metrics.addr=0.0.0.0 \
	--metrics.port=6060 \
