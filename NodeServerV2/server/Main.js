import Web3 from 'web3';
import { ContractManager } from './ContractManager.js';
const INFURA_API_URL = "PLACE_YOUR_WSS_INFURA_API_URL_HERE";
// const LOCAL_TESTNET = "http://localhost:8545";

export class StackTowerWeb3 {

    static ws;

    constructor(wss){
        var web3 = new Web3(INFURA_API_URL);
        const ContractMgr = new ContractManager(web3);
    }

    setWebSocket(ws) {
        if (!StackTowerWeb3.ws){
            StackTowerWeb3.ws = ws;
        }
    }
}