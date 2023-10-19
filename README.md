# op-devnet

## Useful commands

`docker build -f Dockerfile.l1 -t op-devnet-l1 .`
`docker run --name l1_node -d -p 8545:8545 op-devnet-l1:latest`
`docker logs l1_node`
`curl -X POST --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' http://localhost:8545`
