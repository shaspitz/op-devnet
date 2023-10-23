# Deploy Config

This directory contains an op-stack deploy configuration, following the pattern of being named by <chain name>.json. See [docs](https://stack.optimism.io/docs/build/conf/#).

Note "BLOCKHASH" is set during image creation, corresponding to an L1 block hash to serve as the starting point for our Rollup. TIMESTAMP is the timestamp from that same block, represented as a number, not a string like other fields.

Note hardhat accounts are set deterministically, and are used in the deploy config as follows:

* Account #1 is "ADMIN"
* Account #2 is "PROPOSER"
* Account #3 is "BATCHER"
* Account #4 is "SEQUENCER"

TODO(Shawn): determine if batcher and sequencer should use same account.

Where 

> **WARNING**: These accounts, and their private keys, are publicly known. Any funds sent to them on Mainnet or any other live network WILL BE LOST.

- **Account #0 (Unused)**: 
    - Address: `0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266` 
    - Balance: `10000 ETH`
    - Private Key: `0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80`

- **Account #1**: 
    - Address: `0x70997970C51812dc3A010C7d01b50e0d17dc79C8`
    - Balance: `10000 ETH`
    - Private Key: `0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d`

- **Account #2**: 
    - Address: `0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC`
    - Balance: `10000 ETH`
    - Private Key: `0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a`

- **Account #3**: 
    - Address: `0x90F79bf6EB2c4f870365E785982E1f101E93b906`
    - Balance: `10000 ETH`
    - Private Key: `0x7c852118294e51e653712a81e05800f419141751be58f605c371e15141b007a6`

- **Account #4**: 
    - Address: `0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65`
    - Balance: `10000 ETH`
    - Private Key: `0x47e179ec197488593b187f80a00eb0da91f1b9d0b13f8733639f19c30a34926a`
