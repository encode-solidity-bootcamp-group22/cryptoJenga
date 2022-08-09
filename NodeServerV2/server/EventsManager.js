import { StackTowerWeb3 } from "./Main.js";

export class EventsManager {

    constructor(contract) {
        this.initEventListeners(contract)
    }

    broadcastMessage(message) {
        if (StackTowerWeb3.ws){
            StackTowerWeb3.ws.send(message);
        }
    }

    /**
     * Listen for events received from the smart contract, 
     * if there are clients then forward these messages to them.
     * @param {*} contract 
     * @param {*} wss 
     */
    initEventListeners(contract) {
        contract.events.UpdateCount({}, (function(error, events){
            console.log('broadcasting',events.returnValues.count);
            this.broadcastMessage(events.returnValues.count);
        }).bind(this));        
    }
}