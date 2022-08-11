import { StackTowerWeb3 } from "./Main.js";

export class EventsManager {

    constructor(contract) {
        this.initEventListeners(contract)
    }

    broadcastMessage(payload) {
        if (StackTowerWeb3.wss){
            console.log("broadcasting message", payload);
            StackTowerWeb3.wss.clients.forEach((client) => {
                console.log("broadcasting message to client ", client);
                client.send(JSON.stringify(payload));
              });
        }
        else {
            console.log('ws not available');
        }
    }

    /**
     * Listen for events received from the smart contract, 
     * if there are clients then forward these messages to them.
     * @param {*} contract 
     */
    initEventListeners(contract) {
        contract.events.BetMade({}, (function(error, events){
            let payload = {
                eventName: events.event,
                player: events.returnValues._player,
                ethTickerPrice: events.returnValues._EthTicketPrice
            }
            console.log("broadcasting message");
            this.broadcastMessage(payload);
        }).bind(this));

        contract.events.GameState({}, (function(error, events){
            this.broadcastMessage(events);
        }).bind(this));

        contract.events.RoundStarted({}, (function(error, events){
            this.broadcastMessage(events);
        }).bind(this));

        contract.events.RoundEnded({}, (function(error, events){
            this.broadcastMessage(events);
        }).bind(this));

        contract.events.GameEnded({}, (function(error, events){
            this.broadcastMessage(events);
        }).bind(this));

        contract.events.PlayersJoined({}, (function(error, events){
            this.broadcastMessage(events);
        }).bind(this));
    }
}