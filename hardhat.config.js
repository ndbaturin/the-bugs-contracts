require("@nomicfoundation/hardhat-toolbox");
require('@openzeppelin/hardhat-upgrades');
require('dotenv').config();
const helpers = require("@nomicfoundation/hardhat-network-helpers");

const MNEMONIC = process.env.MNEMONIC;
const PRIVATE_KEY = process.env.PRIVATE_KEY;
const ACCOUNTS = MNEMONIC ? { "mnemonic": MNEMONIC } : [PRIVATE_KEY];

task("deploy-test", "Deploys TheBugs contracts for testing")
  .setAction(async (taskArgs) => {
    await hre.run('compile');

    const TheBugs = await ethers.getContractFactory("TheBugs");
    const theBugs = await upgrades.deployProxy(TheBugs, []);
    await theBugs.waitForDeployment()
    const theBugsAddress = await theBugs.getAddress();

    console.log("TheBugs deployed to: ", theBugsAddress);

    const BugMinter = await ethers.getContractFactory("BugMinter");
    const bugMinter = await upgrades.deployProxy(BugMinter, [theBugsAddress]);
    await bugMinter.waitForDeployment()
    const bugMinterAddress = await bugMinter.getAddress();

    console.log("BugMinter deployed to: ", bugMinterAddress);

    const MINTER_ROLE = hre.ethers.id("MINTER_ROLE");
    const grantTx = await theBugs.grantRole(MINTER_ROLE, bugMinterAddress);
    await grantTx.wait();

    console.log("MINTER_ROLE granted to BugMinter");
  });

task("set-all-data", "Catches a bug for you")
  .addParam("theBugs", "The address of the bugs contract")
  .setAction(async (taskArgs) => {
    const theBugsAddress = taskArgs.theBugs;
    const TheBugs = await ethers.getContractFactory("TheBugs");
    const theBugs = TheBugs.attach(theBugsAddress);

    const setTx0 = await theBugs.setSpeciesData(
      0,
      {
        name: "Coperpillar",
        description: "Figths crime",
        image: "ipfs://QmRTsj3pKswas1zeUqAtzCTn94vUECu78eVv2DNcaTKFjs"
      }
    );
    await setTx0.wait();

    const setTx1 = await theBugs.setSpeciesData(
      1,
      {
        name: "Waspassin",
        description: "Eliminates targets",
        image: "ipfs://QmRvw9saBJnBdVFUjMUJEeU9aXGd74iue4YkP2aLHeaaQ2"
      }
    );
    await setTx1.wait();

    const setTx2 = await theBugs.setSpeciesData(
      2,
      {
        name: "Fiddle Cricket",
        description: "Plays violin",
        image: "ipfs://QmPkNKSaSriDSsFaz8eS5gzhepNMAgFiXtecR8Q5LcpfvN"
      }
    );
    await setTx2.wait();

    const setTx3 = await theBugs.setSpeciesData(
      3,
      {
        name: "Soldant",
        description: "Protects his anthill",
        image: "ipfs://Qme6BUz9m8MpP1tuyrTYsPN2yx8wjauQfMfh68MeG2H9c4"
      }
    );
    await setTx3.wait();

    const setTx4 = await theBugs.setSpeciesData(
      4,
      {
        name: "Maffhopper",
        description: "Does shady business",
        image: "ipfs://QmU9tEWtAxaMRjeHP5h8pcA431psZP9N1c4mz2YsqfSWeM"
      }
    );
    await setTx4.wait();

    const setTx5 = await theBugs.setSpeciesData(
      5,
      {
        name: "Thiefsquito",
        description: "Changes items owner",
        image: "ipfs://QmNhM2x2RrcP3ohXfVbj2jtrcqpaJ3P3naDcXJ3KhSnCap"
      }
    );
    await setTx5.wait();

    const setTx6 = await theBugs.setSpeciesData(
      6,
      {
        name: "Pharab",
        description: "Bug of Egypt",
        image: "ipfs://QmbbJLyQaUNmpSTpzYtv8G7jx1k1vZJjrE3Kbiy3ovkKSn"
      }
    );
    await setTx6.wait();

    const setTx7 = await theBugs.setSpeciesData(
      7,
      {
        name: "Discofly",
        description: "Shakes his disco ball",
        image: "ipfs://QmTkmL49Vka86PcXah5be1c6PWFxJLgLKj63MVkaphLkfh"
      }
    );
    await setTx7.wait();

    const setTx8 = await theBugs.setSpeciesData(
      8,
      {
        name: "Lady Bug",
        description: "Do not confuse with ladybug",
        image: "ipfs://QmPpEHcvtPPMGNmbTM6XgXo84oRb4FgLt6WnazJAMQAW3H"
      }
    );
    await setTx8.wait();

    const setTx9 = await theBugs.setSpeciesData(
      9,
      {
        name: "Doctor Bug",
        description: "Conducts evil experiments",
        image: "ipfs://QmbnMpk9HVTtqYhwF3kL8odj4K5dSRaxdCeXrWTBWqbq13"
      }
    );
    await setTx9.wait();

    const setTx10 = await theBugs.setSpeciesData(
      10,
      {
        name: "Rastabug",
        description: "Has red eyes for some reason",
        image: "ipfs://QmRMCW8LRTdWVVTTVm8Pc66Cj3s4mRuwsRBpRuEDLBvr6b"
      }
    );
    await setTx10.wait();

    const setTx11 = await theBugs.setSpeciesData(
      11,
      {
        name: "Mothalhead",
        description: "Has impressive vocals",
        image: "ipfs://QmaGyeAkVKPTXaRnc4pow6rDPcJ1X9kD916qunfgB5Lgqc"
      }
    );
    await setTx11.wait();

    console.log("All data has been set");
  });

task("get-uri", "Catches a bug for you")
  .addParam("theBugs", "The address of the bugs contract")
  .addParam("bugId", "The address of the bugs contract")
  .setAction(async (taskArgs) => {
    const theBugsAddress = taskArgs.theBugs;
    const bugId = taskArgs.bugId;

    const TheBugs = await ethers.getContractFactory("TheBugs");
    const theBugs = TheBugs.attach(theBugsAddress);

    const uri = await theBugs.tokenURI(bugId);
    
    console.log(uri);
  });

task("catch-full", "Catches a bug for you")
  .addParam("bugMinter", "The address of the bug minter contract")
  .setAction(async (taskArgs) => {
    const bugMinterAddress = taskArgs.bugMinter;
    const BugMinter = await ethers.getContractFactory("BugMinter");
    const bugMinter = BugMinter.attach(bugMinterAddress);

    const theBugsAddress = await bugMinter.theBugs();
    const TheBugs = await ethers.getContractFactory("TheBugs");
    const theBugs = TheBugs.attach(theBugsAddress);

    const initTx = await bugMinter.initiateCatch();
    await initTx.wait();
    
    console.log("Catch initiated");

    let bugId;
    theBugs.on("Transfer", (from, to, tokenId, listener) => {
      console.log(listener)
      bugId = tokenId;
    });

    const completeTx = await bugMinter.completeCatch();
    await completeTx.wait();

    console.log("Catch completed");

    while (bugId == null) {
      await sleep(100);
    }

    console.log("You catched bug #", bugId);
  });

function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  networks: {
    amoy: {
      url: process.env.MUMBAI_URL || "https://rpc-amoy.polygon.technology",
      accounts: ACCOUNTS
    },
    goerli: {
      url: process.env.GOERLI_URL || "none",
      accounts: ACCOUNTS,
    },
    sepolia: {
      url: process.env.SEPOLIA_URL || "https://gateway.tenderly.co/public/sepolia",
      accounts: ACCOUNTS
    },
  },
  solidity: {
    version: "0.8.26",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      }
    }
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY,
  },
};
