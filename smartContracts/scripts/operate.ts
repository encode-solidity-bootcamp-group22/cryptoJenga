import {getSigner, getAccountAddress} from "./accountsService";
import "dotenv/config";
import { ethers } from "ethers";

import {deployCryptoJengaContract} from "./deploycryptoJenga";

function convertStringArrayToBytes32(array: string[]) {
  const bytes32Array = [];
  for (let index = 0; index < array.length; index++) {
    bytes32Array.push(ethers.utils.formatBytes32String(array[index]));
  }
  return bytes32Array;
}

async function main() 
{
    const priceFeedAddress = "0x8A753747A1Fa494EC906cE90E9f37563A8AF630e";
    const vrfCoordinator = "0xb3dCcb4Cf7a26f6cf6B120Cf5A73875B7BBc655B";
    const linkFee = 0.1;
    const keyhash = "0x2ed0feb3e7fd2022120aa84fab1945545a9f2ffc9076fd6156fa96eaff4c1311";
    const ticketPriceInUSD = 30;

    const ownerSigner = await getSigner(
      process.env.PRIVATE_KEY_2,
      process.env.MNEMONIC,
      "rinkeby"
    );

    const secondSigner = await getSigner(
      process.env.PRIVATE_KEY_1,
      process.env.MNEMONIC,
      "rinkeby"
    );
    
    const ballotContractAddress = await deployCryptoJengaContract(
      ownerSigner, 
      priceFeedAddress,
      vrfCoordinator,
      linkFee,
      keyhash,
      ticketPriceInUSD
    );


  }
  
  main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });