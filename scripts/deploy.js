require("dotenv").config();
const hre = require("hardhat");

async function main() {
    const [deployer] = await hre.ethers.getSigners();
    console.log("Deploying contracts with the account:", deployer.address);

    const balance = await hre.ethers.provider.getBalance(deployer.address);
    console.log("Account balance:", balance);

    const FreelancePlatform = await hre.ethers.getContractFactory("FreelancePlatform");
    const myContractDeployed = await FreelancePlatform.deploy(); // Adjust the initial supply as needed
    
    console.log("Contact is deployed to:", myContractDeployed.target);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
