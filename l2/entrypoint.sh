#!/bin/sh

echo "Op Component Type: $OP_COMPONENT_TYPE"

if [ "$OP_COMPONENT_TYPE" = "coordinator" ]; then

    # Generate jwt secret for op-node to op-geth auth, place in shared volume
    openssl rand -hex 32 > jwt.txt
    cp jwt.txt /shared-l2-config 

    # Create L2 config files, place in shared volume
    cd /optimism/op-node
    go run cmd/main.go genesis l2 \
        --deploy-config "/shared-optimism/packages/contracts-bedrock/deploy-config/primev-settlement.json" \
        --deployment-dir /shared-optimism/packages/contracts-bedrock/deployments/primev-settlement \
        --outfile.l2 genesis.json \
        --outfile.rollup rollup.json \
        --l1-rpc $ETH_RPC_URL
    cp genesis.json rollup.json /shared-l2-config 

    # Signal setup complete
    touch /tmp/setup_complete

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

elif [ "$OP_COMPONENT_TYPE" = "node" ]; then

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

else
    echo "container type not impl"
fi

# Infinite looop
while true; do
  sleep 1
done
