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
        const AddTotalContract = JSON.parse(
            await readFile(
              new URL('../contracts/AddTotal.json', import.meta.url)
            )
          );
        const netId = await web3.eth.net.getId();
        // console.log('net id is', netId);
        // const deployedNetwork = AddTotalContract.networks[netId];
        // console.log('abi', AddTotalContract.abi);
        // console.log('deployedNetwork address', deployedNetwork.address)
        const AddTotalDeployed = new web3.eth.Contract(
          AddTotalContract.abi,
          "0x43ff6d359d82949e9974f7818a9e13208cf13993"
        );
        console.log(`address deployed to ${AddTotalDeployed.options.address}`);
        console.log(`contract is ${AddTotalDeployed.events}`)
        const EventsMgr = new EventsManager(AddTotalDeployed);
      }     
 }