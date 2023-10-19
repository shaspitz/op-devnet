# op-devnet

## Useful commands

### L1

`docker build -f Dockerfile.l1 -t op-devnet-l1 .`
`docker run --name l1_node -d -p 8545:8545 op-devnet-l1:latest`
`docker logs l1_node`
`curl -X POST --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' http://localhost:8545`

### L2
`docker build -f Dockerfile.l2 -t op-devnet-l2 .`
`docker run --name l2_node -d op-devnet-l2:latest`
`docker run -it --name l2_node op-devnet-l2:latest bash`
