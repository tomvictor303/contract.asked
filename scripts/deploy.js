require("dotenv").config();
const hre = require("hardhat");

async function main() {
    const [deployer] = await hre.ethers.getSigners();
    console.log("Deploying contracts with the account:", deployer.address);

    const balance = await hre.ethers.provider.getBalance(deployer.address);
    console.log("Account balance:", balance.toString());

    // Set the token address (replace with actual address or use environment variable)
    const tokenAddress = process.env.ASK_TOKEN_ADDRESS || "0xYourTokenAddressHere";

    // Regular expression to validate Ethereum address
    const isAddress = (address) => /^0x[a-fA-F0-9]{40}$/.test(address);

    // Ensure the token address is valid
    if (!isAddress(tokenAddress)) {
        throw new Error("Invalid token address provided");
    }

    const FreelancePlatform = await hre.ethers.getContractFactory("FreelancePlatform");
    const myContractDeployed = await FreelancePlatform.deploy(tokenAddress);

    console.log("Contract is deployed to:", myContractDeployed.target);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
