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
        --verbosity=5\
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
        --networkid=$L2_CHAIN_ID \
        --rpc.allow-unprotected-txs \
        --authrpc.addr="0.0.0.0"\
        --authrpc.port="8551" \
        --authrpc.vhosts="*" \
        --authrpc.jwtsecret=/shared-l2-config/jwt.txt \
        --gcmode=archive \
        --metrics \
        --metrics.addr=0.0.0.0 \
        --metrics.port=6060 \

elif [ "$OP_COMPONENT_TYPE" = "node" ]; then

    # Start op-node

    # TODO: see pattern from src docker compose on how op-node is spun up -> it overrides the the entrypoint
    # This even explains the test-jwt-secret shit


    # following removed
    #   --snapshotlog.file=/op_log/snapshot.log \

    cd /optimism/op-node
    ./bin/op-node \
      --l1=ws://l1:8546 \
      --l2=http://l2-geth:8551 \
      --l2.jwt-secret=/shared-l2-config/jwt.txt \
      --sequencer.enabled \
      --sequencer.l1-confs=0 \
      --verifier.l1-confs=0 \
      --p2p.sequencer.key=8b3a350cf5c34c9194ca85829a2df0ec3153be0318b5e2d3348e872092edffba \
      --rollup.config=/shared-l2-config/rollup.json \
      --rpc.addr=0.0.0.0 \
      --rpc.port=8545 \
      --p2p.listen.ip=0.0.0.0 \
      --p2p.listen.tcp=9003 \
      --p2p.listen.udp=9003 \
      --p2p.scoring.peers=light \
      --p2p.ban.peers=true \
      --p2p.priv.path=/shared-optimism/ops-bedrock/p2p-node-key.txt \
      --metrics.enabled \
      --metrics.addr=0.0.0.0 \
      --metrics.port=7300 \
      --pprof.enabled \
      --rpc.enable-admin 

else
    echo "container type not impl"
fi

# Infinite looop
while true; do
  sleep 1
done
