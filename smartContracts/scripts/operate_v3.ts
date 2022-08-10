import {getSigner, getAccountAddress} from "./accountsService";
import "dotenv/config";
import { Contract, ethers } from "ethers";
import * as cryptoJengaJson from "../artifacts/contracts/cryptoJenga_v3.sol/cryptoJengav3.json";
import {CryptoJengav3} from "../typechain-types";

import {deployCryptoJengaContract} from "./deploycryptoJenga_v3";
import { exit } from "process";

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

    const provider = ethers.providers.getDefaultProvider("rinkeby");

    const ownerSignerWallet = await getSigner(
      process.env.PRIVATE_KEY_2,
      process.env.MNEMONIC,
      "rinkeby"
    );

    const secondSignerWallet = await getSigner(
      process.env.PRIVATE_KEY_1,
      process.env.MNEMONIC,
      "rinkeby"
    );
    
    const ballotContractAddress = await deployCryptoJengaContract(
      ownerSignerWallet, 
      priceFeedAddress,
      vrfCoordinator,
      linkFee,
      keyhash,
      ticketPriceInUSD
    );

    const ownerSigner = ownerSignerWallet.connect(provider);
    const gameContractForOwner: CryptoJengav3 = new Contract(
      ballotContractAddress,
      cryptoJengaJson.abi,
      ownerSigner
    ) as CryptoJengav3;

    // get the game state
    let gameState = await gameContractForOwner.game_state();
    console.log(`Game state ${gameState}`)

    // start the game
    console.log("Starting the game ...");
    let tx = await gameContractForOwner.startGame();
    console.log(`Start game transaction ${tx.hash}; waiting for confirmation.`)
    await tx.wait(1);
    console.log(`Start game transaction ${tx.hash}; confirmed.`)

    // get the game state
    gameState = await gameContractForOwner.game_state();
    console.log(`Game state ${gameState}`)

    // place bet
    const signedMessage = await ownerSigner.signMessage("Pizza");
    console.log(`The signed message is:\n${signedMessage}`);
    const sig = ethers.utils.splitSignature(signedMessage);
    console.log(`Place bet with 0.03 Ether ... sig.s: ${sig.s}`);
    
    tx = await gameContractForOwner.bet(1, 1, sig.v, sig.r, sig.s, {value:ethers.utils.parseEther("0.03")});
    console.log(`Place bet transaction ${tx.hash}; waiting for confirmation.`)
    await tx.wait(1);
    console.log(`Place bet transaction ${tx.hash}; confirmed.`)

    // withdraw the fund
    tx = await gameContractForOwner.withdrawEth();
    await tx.wait(1);

    // reveal the bet
    tx = await gameContractForOwner.revealBet(1, 1, "Pizza");
    console.log(`Reveal bet transaction ${tx.hash}; waiting for confirmation.`)
    await tx.wait(1);
    console.log(`Reveal bet transaction ${tx.hash}; confirmed.`)

    // second player to place bet
    const secondSigner = secondSignerWallet.connect(provider);
    const signedMessage2 = await secondSigner.signMessage("Cake");
    console.log(`The signed message is:\n${signedMessage2}`);
    const sig2 = ethers.utils.splitSignature(signedMessage2);

    console.log("Second player place bet with 0.03 Ether ...");
    tx = await gameContractForOwner.connect(secondSigner).bet(1, 1, sig2.v, sig2.r, sig2.s, {value:ethers.utils.parseEther("0.03")});
    console.log(`Place bet transaction ${tx.hash}; waiting for confirmation.`)
    await tx.wait(1);
    console.log(`Place bet transaction ${tx.hash}; confirmed.`)

    // withdraw the fund
    tx = await gameContractForOwner.connect(ownerSigner).withdrawEth();
    await tx.wait(1);

    // reveal the bet
    tx = await gameContractForOwner.connect(secondSigner).revealBet(1, 1, "Cake");
    console.log(`Reveal bet transaction ${tx.hash}; waiting for confirmation.`)
    await tx.wait(1);
    console.log(`Reveal bet transaction ${tx.hash}; confirmed.`)

    // get the players
    console.log("getting number of players");
    const players = await gameContractForOwner.getNumberofPlayers();
    console.log(`Number of players: ${players.toNumber()}`);

    exit;

  }
  
  main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });