# op-devnet

This proj is heavily inspired by https://github.com/ethereum-optimism/optimism/tree/develop/bedrock-devnet, while trying to stay consistent to mev-commit's docker/shell setup.

## Instructions
* Ensure docker and docker-compose are installed. 
* `docker-compose up -d --build --remove-orphans` to spin up system. 
* `docker logs op-devnet-coordinator-1` etc. to inspect individual container logs.
* `docker exec -it op-devnet-coordinator-1 /bin/sh` etc. to shell into one of the containers. 
* `docker-compose down -v` to bring down system and clear volumes.

## Design

*coordinator* is responsible for general setup of both L1 and L2. Genesis state creation, L1 contract deployment (enacted with emphemeral dev-mode geth), and initiazing processes with custom config.

*l1-geth* is a single node geth instance running a POA protocol, Clique. 

*op-geth* is the execution client for the L2 rollup. 

*op-node* is the psuedo consensus client for the L2 rollup, primarily responsible for deriving L2 state from submitted data on L1. 

*op-batcher* takes transactions from the L2 Sequencer and publishes those transactions to L1.

*op-proposer* proposes new state roots for L2.

## TODO: Experiment with non-default deploy config mutations, use op-stack validation afterwards 

## TODO: various naming and dir changes in coordinator entrypoint 
