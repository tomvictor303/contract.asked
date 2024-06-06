require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.24",
  networks: {
      bsctestnet: {
          url: "https://data-seed-prebsc-1-s1.binance.org:8545/",
          accounts: [`0x${process.env.TEST_PRIVATE_KEY}`]
      },
      bscmainnet: {
          url: "https://bsc-dataseed.binance.org/",
          accounts: [`0x${process.env.MAIN_PRIVATE_KEY}`]
      }
  }
};
