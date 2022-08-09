import Web3 from 'web3';

const INFURA_API_URL = "https://ropsten.infura.io/v3/481c7a826bc445ccb7b417ce9a6096c7";

export class Test {
    constructor(){
        var web3 = new Web3(INFURA_API_URL);
    }
}