import { ethers, Signer } from "ethers";
import "dotenv/config";
import * as cryptoJengaJson from "../artifacts/contracts/cryptoJenga_v3.sol/cryptoJengav3.json";
import {CryptoJengav3} from "../typechain-types";

function convertStringArrayToBytes32(array: string[]) {
  const bytes32Array = [];
  for (let index = 0; index < array.length; index++) {
    bytes32Array.push(ethers.utils.formatBytes32String(array[index]));
  }
  return bytes32Array;
}

async function  deployCryptoJengaContract( 
  signerWallet: ethers.Wallet,
  priceFeedAddress: string,
  vrfCoordinator : string,
  linkFee: number,
  keyhash: string,
  ticketPriceInUSD: number
) 
{
  const GAS_OPTIONS = {
    maxFeePerGas: 60 * 10 ** 9,
    maxPriorityFeePerGas: 60 * 10 ** 9,
  };


  const provider = ethers.providers.getDefaultProvider("rinkeby");
  const signer = signerWallet.connect(provider);
  const balanceBN = await signer.getBalance();
  const balance = Number(ethers.utils.formatEther(balanceBN));
  console.log(`Wallet balance ${balance}`);
  if (balance < 0.01) {
    throw new Error("Not enough ether");
  }

  console.log("");
  console.log("======Deploying CryptoJenga V3 contract======");
  console.log("");
  
  const cryptoJengaFactory = new ethers.ContractFactory(
    cryptoJengaJson.abi,
    cryptoJengaJson.bytecode, 
    signer
  );

  const cryptoJengaContract = (await cryptoJengaFactory.deploy(
    priceFeedAddress,
    vrfCoordinator,
    ethers.utils.parseEther(linkFee.toFixed(18)),
    keyhash,
    ethers.utils.parseEther(ticketPriceInUSD.toFixed(18)),
    10*60, // round duration 10 mins
    5*60, // reveal duration 5 mins
    3 // number of round
   // GAS_OPTIONS
  )) as CryptoJengav3;
  
  console.log("Awaiting confirmations");
  await cryptoJengaContract.deployed();

  console.log("Completed");
  console.log(`CryptoJenga Contract deployed at ${cryptoJengaContract.address}`);

  return cryptoJengaContract.address;
}

export {deployCryptoJengaContract};
