# op-devnet

Instructions to run: 

1. fillout `.env` with `L1_SYNC_URL` for hardhat to fetch L1 mainnet state as needed.
2. Ensure docker and docker-compose are installed. 
3. `docker-compose up -d --build` to run system. 
4. `docker logs op-devnet-coordinator-1` etc. to inspect individual container logs.
5. `docker exec -it op-devnet-coordinator-1 /bin/sh` etc. to shell into one of the containers. 
6. `docker-compose down -v` to bring down system and clear volumes.

## TODO: Explain container design and role of L2 coordinator to prevent race conditions
