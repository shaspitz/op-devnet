#!/bin/sh

echo "Op Component Type: $OP_COMPONENT_TYPE"

if [ "$OP_COMPONENT_TYPE" = "coordinator" ]; then

    # cp contracts-bedrock dir from src to shared volume
    cp -r /optimism/packages/contracts-bedrock/* /shared-contracts-bedrock

    DEPLOY_CONFIG_PATH="/shared-contracts-bedrock/deploy-config/primev-settlement.json"

    # Copy deploy config from tmp location to shared volume loc
    cp /tmp/deploy-config/primev-settlement.json $DEPLOY_CONFIG_PATH

    echo "will connect to L1 ETH_RPC_URL at: $ETH_RPC_URL"

    # Query L1 for latest finalized block
    OUTPUT=$(cast block finalized --rpc-url $ETH_RPC_URL | grep -E "(timestamp|hash|number)")

    # Extract values from response 
    HASH_VALUE=$(echo "$OUTPUT" | grep "hash" | awk '{print $2}')
    TIMESTAMP_VALUE=$(echo "$OUTPUT" | grep "timestamp" | awk '{print $2}')

    # Echo values to verify
    echo "Finalized block hash: $HASH_VALUE"
    echo "Finalized block timestamp: $TIMESTAMP_VALUE"

    # Overwrite deploy config with obtained values 
    sed -i 's/"l2OutputOracleStartingTimestamp": "TIMESTAMP",/"l2OutputOracleStartingTimestamp": '"$TIMESTAMP_VALUE"',/' $DEPLOY_CONFIG_PATH
    sed -i 's/"l1StartingBlockTag": "BLOCKHASH",/"l1StartingBlockTag": "'"$HASH_VALUE"'",/' $DEPLOY_CONFIG_PATH
  
    # Check our custom deploy config for breaking changes
    cd /optimism
    go run op-chain-ops/cmd/check-deploy-config/main.go --path $DEPLOY_CONFIG_PATH

    # Generate jwt secret for op-node to op-geth auth, place in shared volume
    openssl rand -hex 32 > jwt.txt
    cp jwt.txt /shared-l2-config 

    # Create deployments dir, deploy L1 contracts
    mkdir -p /shared-contracts-bedrock/deployments/primev-settlement
    cd /shared-contracts-bedrock
    forge script scripts/Deploy.s.sol:Deploy --private-key $PRIVATE_KEY --broadcast --rpc-url $ETH_RPC_URL
    forge script scripts/Deploy.s.sol:Deploy --sig 'sync()' --private-key $PRIVATE_KEY --broadcast --rpc-url $ETH_RPC_URL

    # Create L2 config files, place in shared volume
    cd /optimism/op-node
    go run cmd/main.go genesis l2 \
        --deploy-config /shared-contracts-bedrock/deploy-config/primev-settlement.json \
        --deployment-dir /shared-contracts-bedrock/deployments/primev-settlement \
        --outfile.l2 genesis.json \
        --outfile.rollup rollup.json \
        --l1-rpc $ETH_RPC_URL
    cp genesis.json rollup.json /shared-l2-config 

    # Signal service is healthy for other containers to start
    touch /tmp/service_is_healthy

elif [ "$OP_COMPONENT_TYPE" = "node" ]; then

    # Block until op-geth has started
    while true; do
        response=$(curl -s -o /dev/null -w "%{http_code}" "http://l2-geth:8545")
        # Check if resp between 200 and 400
        if [ "$response" -ge 200 ] && [ "$response" -lt 400 ]; then
            echo "Server responded with HTTP code $response"
            break
        else
            echo "No response from server or server error. HTTP code: $response. Retrying..."
            sleep 5  
        fi
    done

    # Start op-node
    cd /optimism/op-node
    ./bin/op-node \
        --l2=http://l2-geth:8551 \
        --l2.jwt-secret=/shared-l2-config/jwt.txt \
        --sequencer.enabled \
        --sequencer.l1-confs=5 \
        --verifier.l1-confs=4 \
        --rollup.config=/shared-l2-config/rollup.json \
        --rpc.addr=0.0.0.0 \
        --rpc.port=8547 \
        --p2p.disable \
        --rpc.enable-admin \
        --p2p.sequencer.key=$SEQ_KEY \
        --l1=$ETH_RPC_URL \
        --l1.rpckind=debug_geth

elif [ "$OP_COMPONENT_TYPE" = "geth" ]; then

    # Create datadir, init op-geth
    cd /op-geth
    mkdir datadir
    build/bin/geth init --datadir=datadir /shared-l2-config/genesis.json

    # Start op-geth
    ./build/bin/geth \
        --datadir ./datadir \
        --http \
        --http.corsdomain="*" \
        --http.vhosts="*" \
        --http.port=8545 \
        --http.addr=0.0.0.0 \
        --http.api=web3,debug,eth,txpool,net,engine \
        --ws \
        --ws.addr=0.0.0.0 \
        --ws.port=8546 \
        --ws.origins="*" \
        --ws.api=debug,eth,txpool,net,engine \
        --syncmode=full \
        --gcmode=archive \
        --nodiscover \
        --maxpeers=0 \
        --networkid=99999 \
        --authrpc.vhosts="*" \
        --authrpc.addr=0.0.0.0 \
        --authrpc.port=8551 \
        --authrpc.jwtsecret=/shared-l2-config/jwt.txt \
        --rollup.disabletxpoolgossip=true

else
    echo "container type not impl"
fi

# Infinite looop
while true; do
  sleep 1
done
