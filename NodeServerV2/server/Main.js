import Web3 from 'web3';
import { ContractManager } from './ContractManager.js';
const INFURA_API_URL = "wss://ropsten.infura.io/ws/v3/481c7a826bc445ccb7b417ce9a6096c7";
// const LOCAL_TESTNET = "http://localhost:8545";

export class StackTowerWeb3 {

    static wss;

    constructor(wss){
        var web3 = new Web3(INFURA_API_URL);
        const ContractMgr = new ContractManager(web3);
    }

    setWebSocket(wss) {
        StackTowerWeb3.wss = wss;
    }
}