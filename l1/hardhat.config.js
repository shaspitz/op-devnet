module.exports = {
    defaultNetwork: "hardhat",
    networks: {
      hardhat: {
        mining: {
          // 12 second L1 block time
          auto: false,
          interval: 12000 
        },
        forking: {
          // Will be mutated from env var in .env
          url: "NULL_URL",
        },
      },
    },
  }
