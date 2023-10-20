#!/bin/sh

echo "Op Component Type: $OP_COMPONENT_TYPE"

if [ "$OP_COMPONENT_TYPE" = "coordinator" ]; then
    echo "ETH_RPC_URL: $ETH_RPC_URL"

    # Query L1 for latest finalized block
    OUTPUT=$(cast block finalized --rpc-url $ETH_RPC_URL | grep -E "(timestamp|hash|number)")

    # Extract values from response 
    HASH_VALUE=$(echo "$OUTPUT" | grep "hash" | awk '{print $2}')
    TIMESTAMP_VALUE=$(echo "$OUTPUT" | grep "timestamp" | awk '{print $2}')

    # Echo values to verify
    echo "Finalized block hash: $HASH_VALUE"
    echo "Finalized block timestamp: $TIMESTAMP_VALUE"

    # Overwrite deploy config with obtained values 
    FILE_PATH="/optimism/packages/contracts-bedrock/deploy-config/primev-settlement.json"
    sed -i 's/"l2OutputOracleStartingTimestamp": TIMESTAMP,/"l2OutputOracleStartingTimestamp": '"$TIMESTAMP_VALUE"',/' $FILE_PATH
    sed -i 's/"l1StartingBlockTag": "BLOCKHASH",/"l1StartingBlockTag": "'"$HASH_VALUE"'",/' $FILE_PATH

else
    echo "Not coordinator, add func later"
fi

# Infinite looop
while true; do
  sleep 1
done
