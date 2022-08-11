// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MockGame {
    event BetMade(address _player, uint256 _EthTicketPrice);
    event GameState(string _currentState);
    event RoundStarted(uint256 _currentRoundNumber);
    event RoundEnded(uint256 _currentRoundNumber);
    event GameEnded(address _gameWinner, uint256 amountWon);
    event PlayersJoined(address[] players);

    function emitBetMade(address _player, uint256 _EthTicketPrice) public {
        emit BetMade(_player, _EthTicketPrice);
    }

    function emitGameState(string memory _currentState) public {
        emit GameState(_currentState);
    }

    function emitRoundStarted(uint256 _currentRoundNumber) public {
        emit RoundStarted(_currentRoundNumber);
    }

    function emitRoundEnded(uint256 _currentRoundNumber) public {
        emitRoundEnded(_currentRoundNumber);
    }    

    function emitGameEnded(address _gameWinner, uint256 amountWon) public {
        emit GameEnded(_gameWinner, amountWon);
    }

    function emitPlayersJoined(address[] memory players) public {
        emit PlayersJoined(players);
    }  
}