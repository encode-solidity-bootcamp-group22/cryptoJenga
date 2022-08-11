using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System.Threading.Tasks;

#if UNITY_WEBGL
public class CryptoJenga: MonoBehaviour
{
    // REPLACE ME!!!
    const string abi = "[ { \"anonymous\": false, \"inputs\": [ { \"indexed\": false, \"internalType\": \"address\", \"name\": \"_player\", \"type\": \"address\" }, { \"indexed\": false, \"internalType\": \"uint256\", \"name\": \"_EthTicketPrice\", \"type\": \"uint256\" } ], \"name\": \"BetMade\", \"type\": \"event\" }, { \"inputs\": [ { \"internalType\": \"address\", \"name\": \"_player\", \"type\": \"address\" }, { \"internalType\": \"uint256\", \"name\": \"_EthTicketPrice\", \"type\": \"uint256\" } ], \"name\": \"emitBetMade\", \"outputs\": [], \"stateMutability\": \"nonpayable\", \"type\": \"function\" }, { \"inputs\": [ { \"internalType\": \"address\", \"name\": \"_gameWinner\", \"type\": \"address\" }, { \"internalType\": \"uint256\", \"name\": \"amountWon\", \"type\": \"uint256\" } ], \"name\": \"emitGameEnded\", \"outputs\": [], \"stateMutability\": \"nonpayable\", \"type\": \"function\" }, { \"inputs\": [ { \"internalType\": \"string\", \"name\": \"_currentState\", \"type\": \"string\" } ], \"name\": \"emitGameState\", \"outputs\": [], \"stateMutability\": \"nonpayable\", \"type\": \"function\" }, { \"inputs\": [ { \"internalType\": \"address[]\", \"name\": \"players\", \"type\": \"address[]\" } ], \"name\": \"emitPlayersJoined\", \"outputs\": [], \"stateMutability\": \"nonpayable\", \"type\": \"function\" }, { \"inputs\": [ { \"internalType\": \"uint256\", \"name\": \"_currentRoundNumber\", \"type\": \"uint256\" } ], \"name\": \"emitRoundEnded\", \"outputs\": [], \"stateMutability\": \"nonpayable\", \"type\": \"function\" }, { \"inputs\": [ { \"internalType\": \"uint256\", \"name\": \"_currentRoundNumber\", \"type\": \"uint256\" } ], \"name\": \"emitRoundStarted\", \"outputs\": [], \"stateMutability\": \"nonpayable\", \"type\": \"function\" }, { \"anonymous\": false, \"inputs\": [ { \"indexed\": false, \"internalType\": \"address\", \"name\": \"_gameWinner\", \"type\": \"address\" }, { \"indexed\": false, \"internalType\": \"uint256\", \"name\": \"amountWon\", \"type\": \"uint256\" } ], \"name\": \"GameEnded\", \"type\": \"event\" }, { \"anonymous\": false, \"inputs\": [ { \"indexed\": false, \"internalType\": \"string\", \"name\": \"_currentState\", \"type\": \"string\" } ], \"name\": \"GameState\", \"type\": \"event\" }, { \"anonymous\": false, \"inputs\": [ { \"indexed\": false, \"internalType\": \"address[]\", \"name\": \"players\", \"type\": \"address[]\" } ], \"name\": \"PlayersJoined\", \"type\": \"event\" }, { \"anonymous\": false, \"inputs\": [ { \"indexed\": false, \"internalType\": \"uint256\", \"name\": \"_currentRoundNumber\", \"type\": \"uint256\" } ], \"name\": \"RoundEnded\", \"type\": \"event\" }, { \"anonymous\": false, \"inputs\": [ { \"indexed\": false, \"internalType\": \"uint256\", \"name\": \"_currentRoundNumber\", \"type\": \"uint256\" } ], \"name\": \"RoundStarted\", \"type\": \"event\" } ]";

    // REPLACE ME !!!
    const string contract = "0x7e11ba6e44654ad8258d30bd0331680fe849c6f0";

    // set chain: ethereum, moonbeam, polygon etc
    string chain = "ethereum";
    // set network mainnet, testnet
    string network = "ropsten";
    // smart contract method to call

    async public void mockBet()
    {
        try
        {
            string to = "0x428066dd8A212104Bc9240dCe3cdeA3D3A0f7979";
            // amount in wei to send
            string value = "12300000000000";
            // gas limit OPTIONAL
            string gasLimit = "";
            // gas price OPTIONAL
            string gasPrice = "";
            string response = await Web3GL.SendTransaction(to, value, gasLimit, gasPrice);
            Debug.Log(response);
        }
        catch (Exception e)
        {
            Debug.LogException(e, this);
        }
    }

public async Task<string> Bet(int gameId, int roundNumber, string value)
    {
        Debug.Log("bet value is " + value);
        // smart contract method to call
        string method = "bet";

        // array of arguments for contract
        string args = "["+gameId+", "+roundNumber+", \"Pizza\"]";
        // value in wei
        string gasLimit = "";
        // gas price OPTIONAL
        string gasPrice = "";
        // connects to user's browser wallet (metamask) to update contract state

        string response = await Web3GL.SendContract(method, abi, contract, args, value, gasLimit, gasPrice);
        Debug.Log(response);
        return response;
    }

    public async Task<string> GetPlayerAddresses()
    {
        string method = "emitPlayersJoined";
        // array of arguments for contract
        string args = "[]";
        // connects to user's browser wallet to call a transaction
        string response = await EVM.Call(chain, network, contract, abi, method, args);
        // display response in game
        print("Player addresses " + response);
        Debug.Log(response);
        return response;
    }
}
#endif