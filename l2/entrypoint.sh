#!/bin/sh

echo "Op Component Type: $OP_COMPONENT_TYPE"

if [ "$OP_COMPONENT_TYPE" = "coordinator" ]; then

    # Only the coordinator copies contracts-bedrock dir from src to shared volume
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
    sed -i 's/"l2OutputOracleStartingTimestamp": TIMESTAMP,/"l2OutputOracleStartingTimestamp": '"$TIMESTAMP_VALUE"',/' $DEPLOY_CONFIG_PATH
    sed -i 's/"l1StartingBlockTag": "BLOCKHASH",/"l1StartingBlockTag": "'"$HASH_VALUE"'",/' $DEPLOY_CONFIG_PATH

else
    echo "Not coordinator, add func later"
fi

# Infinite looop
while true; do
  sleep 1
done
