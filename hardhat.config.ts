import "@nomicfoundation/hardhat-chai-matchers";
import "@nomicfoundation/hardhat-toolbox";
import "@openzeppelin/hardhat-upgrades";
import "@typechain/hardhat";
import { config as dotEnvConfig } from "dotenv";
import "hardhat-contract-sizer";
import "hardhat-ignore-warnings";
import { HardhatUserConfig } from "hardhat/config";
dotEnvConfig();

const config: HardhatUserConfig = {
  solidity: {
    compilers: [
      {
        version: "0.8.18",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
          viaIR: true,
        },
      },
    ],
  },
  etherscan: {
    apiKey: {
      bscTestnet: process.env.BSCSCAN_API_KEY!,
      bsc: process.env.BSCSCAN_API_KEY!,
    },
  },
  networks: {
    hardhat: {
      allowBlocksWithSameTimestamp: true,
    },
    bscTestnet: {
      url: process.env.BSC_TESTNET_RPC!,
      accounts: [process.env.BSC_TESTNET_PRIVATE_KEY!],
      gasPrice: 10 * Math.pow(10, 9),
      blockGasLimit: 10000000,
    },
    bsc: {
      url: process.env.BSC_MAINNET_RPC!,
      accounts: [process.env.BSC_MAINNET_PRIVATE_KEY!],
      gasPrice: 5 * Math.pow(10, 9),
      blockGasLimit: 10000000,
    },
  },
};

export default config;
