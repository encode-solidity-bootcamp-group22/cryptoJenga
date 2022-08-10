import {getSigner, getAccountAddress} from "./accountsService";
import "dotenv/config";
import { Contract, ethers } from "ethers";
import * as mockGameJson from "../artifacts/contracts/MockGame.sol/MockGame.json";
import {MockGame} from "../typechain-types";

import { exit } from "process";



const provider = ethers.providers.getDefaultProvider("rinkeby");

async function main() 
{
    const ownerSignerWallet = await getSigner(
      process.env.PRIVATE_KEY_2,
      process.env.MNEMONIC,
      "rinkeby"
    );
    
    const signer = ownerSignerWallet.connect(provider);

    const mockGameFactory = new ethers.ContractFactory(
      mockGameJson.abi,
      mockGameJson.bytecode, 
      signer
    );
  
    const mockGameContract = (await mockGameFactory.deploy()) as MockGame;
    
    console.log("Awaiting confirmations");
    await mockGameContract.deployed();
  
    console.log("Completed");
    console.log(`MockGame Contract deployed at ${mockGameContract.address}`);

    
    exit;

  }
  
  main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });