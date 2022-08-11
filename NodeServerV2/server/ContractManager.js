/**
 * Initializes the contract
 */
import { readFile } from 'fs/promises';
import { EventsManager } from './EventsManager.js';

export class ContractManager { 
     constructor(web3){
      const contract = this.setContract(web3);
     }
 
     async setContract(web3, wss) {
        const GameContract = JSON.parse(
            await readFile(
              new URL('../contracts/MockGame.json', import.meta.url)
            )
          );
        const GameContractDeployed = new web3.eth.Contract(
          GameContract.abi,
          "0x7e11ba6e44654ad8258d30bd0331680fe849c6f0"
        );
        console.log(`address deployed to ${GameContractDeployed.options.address}`);
        console.log(`contract is ${GameContractDeployed.events}`)
        const EventsMgr = new EventsManager(GameContractDeployed);
      }     
 }