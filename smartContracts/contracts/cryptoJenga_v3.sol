// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Counters.sol";



contract cryptoJengav3 is VRFConsumerBase, Ownable {

    uint256 public USDTicketPrice;
    address payable[] players;
    address payable[] winningPlayers;
    uint256 public randomness;
    AggregatorV3Interface internal ethUsdPriceFeed;
    LinkTokenInterface LINKTOKEN;
    address link_token_contract = 0x01BE23585060835E02B77ef475b0Cc51aA1e0709;
    uint256 public RoundStartTime;
    uint256 RoundDuration; // in seconds
    uint256 RevealDuration; // in seconds
    uint256 TotalRounds;
    uint256 CurrentRound;

    using ECDSA for bytes32;
    mapping(uint256 => mapping(uint256 => mapping ( address => bool))) placedBet; 
    mapping(uint256 => mapping(uint256 => mapping ( address => Bet))) bets; //bets[gameId][roundNumber][playerAddress]
    mapping(address=>uint256) blocksWon;

    mapping(uint256 => uint256) GameWinningPool; //gameId => amount
    mapping(uint256 => uint256) GameFeePool; // gameId => amount

    address payable [] participants;
    mapping(address => bool) participated;
    address payable public gameWinner;


    struct Bet {
        uint256 betAmount;
        Signature betSignature;
        AvailableChoice choiceBet;
    }

    struct Signature {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    enum GAME_STATE {
        INITIALIZED,
        OPEN,
        REVEAL,
        CLOSED,
        CHOOSEROUNDWINNER,
        CALCULATING_WINNER
    }

    enum AvailableChoice {
        Pizza,
        Cake,
        Sandwich,
        Sausage,
        Pancake,
        HotDog,
        MacAndCheese,
        Invalid
    }

    GAME_STATE public game_state;
    uint256 public LinkFee;
    bytes32 public keyhash;
    event RequestedRandomness(bytes32 requestId);
    event BetMade(address _player, uint256 _EthTicketPrice);
    event GameState(string _currentState);
    event RoundStarted(uint256 _currentRoundNumber);
    event RoundEnded(uint256 _currentRoundNumber);
    event RevealStarted(uint256 _currentRoundNumber);
    event RevealEnded(uint256 _currentRoundNumber);
    event GameEdned(address _gameWinner);

    constructor(
        address _priceFeedAddress,
        address _vrfCoordinator,
        uint256 _fee,
        bytes32 _keyhash,
        uint256 _USDTicketPrice,
        uint256 _roundDuration,
        uint256 _revealDuration,
        uint256 _totalRounds
    ) VRFConsumerBase(_vrfCoordinator, link_token_contract){
        USDTicketPrice = _USDTicketPrice;
        ethUsdPriceFeed = AggregatorV3Interface(_priceFeedAddress);
        //* Network: Rinkeby
        //* Aggregator: ETH/USD
        //* _priceFeedAddress= 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        game_state = GAME_STATE.INITIALIZED;
        LinkFee = _fee;
        keyhash = _keyhash;
        LINKTOKEN = LinkTokenInterface(link_token_contract);

        RoundDuration = _roundDuration;
        RevealDuration = _revealDuration;
        TotalRounds = _totalRounds;

        //fee = 100000000000000000 (0.1 Link) 
        //US TicketPrice = 30000000000000000000 ($30)
        //vrfCoordinator = 0xb3dCcb4Cf7a26f6cf6B120Cf5A73875B7BBc655B
        //keyHash = 0x2ed0feb3e7fd2022120aa84fab1945545a9f2ffc9076fd6156fa96eaff4c1311

    }
    function bet(        
        uint256 gameId,
        uint256 roundNumber,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) public payable {
        require(game_state==GAME_STATE.OPEN);
        require(msg.value >= TicketPrice(), "Not enough ETH");
        require( (block.timestamp - RoundStartTime) < RoundDuration, "You are too late for this round");
        require(placedBet[gameId][roundNumber][msg.sender] == false, "You already place bet in this round");

        if ( ! participated[msg.sender])
        {
            participated[msg.sender] = true;
            participants.push(payable(msg.sender));
        }

        placedBet[gameId][roundNumber][msg.sender] = true;
        bets[gameId][roundNumber][msg.sender] = Bet({betAmount: msg.value, betSignature: Signature({v: _v, r: _r, s: _s}), choiceBet: AvailableChoice.Invalid});

        uint256 amountGotoWinningPool = msg.value * 90 / 100;
        GameWinningPool[gameId] += amountGotoWinningPool;
        GameFeePool[gameId] += (msg.value - amountGotoWinningPool);

        players.push(payable(msg.sender));
        emit BetMade(msg.sender, msg.value);
    }

    function startGame() public onlyOwner {
        require(game_state == GAME_STATE.INITIALIZED, "Can't start a new game");
        game_state = GAME_STATE.OPEN;
        RoundStartTime = block.timestamp;
        CurrentRound = 1;
        emit GameState("Open");
        emit RoundStarted(CurrentRound);
    }

    function revealBet (
        uint256 gameId,
        uint256 roundNumber,
        string calldata betString
    ) public {
        require(placedBet[gameId][roundNumber][msg.sender] == true, "You didn't place bet in this round");

        Bet storage myBet = bets[gameId][roundNumber][msg.sender];
        address messageSigner = verifyString(
            betString,
            myBet.betSignature.v,
            myBet.betSignature.r,
            myBet.betSignature.s
        );
        require(msg.sender == messageSigner, "Invalid seed");
        
        if (keccak256(abi.encodePacked((betString))) == keccak256(abi.encodePacked(("Pizza"))))
        {
            myBet.choiceBet = AvailableChoice.Pizza;
        } 
        else if (keccak256(abi.encodePacked((betString))) == keccak256(abi.encodePacked(("Cake"))))
        {
            myBet.choiceBet = AvailableChoice.Cake;
        }
        else if (keccak256(abi.encodePacked((betString))) == keccak256(abi.encodePacked(("Sandwich"))))
        {
            myBet.choiceBet = AvailableChoice.Sandwich;
        }
        else if (keccak256(abi.encodePacked((betString))) == keccak256(abi.encodePacked(("Sausage"))))
        {
            myBet.choiceBet = AvailableChoice.Sausage;
        }
        else if (keccak256(abi.encodePacked((betString))) == keccak256(abi.encodePacked(("Pancake"))))
        {
            myBet.choiceBet = AvailableChoice.Pancake;
        }
        else if (keccak256(abi.encodePacked((betString))) == keccak256(abi.encodePacked(("HotDog"))))
        {
            myBet.choiceBet = AvailableChoice.HotDog;
        }
        else if (keccak256(abi.encodePacked((betString))) == keccak256(abi.encodePacked(("MacAndCheese"))))
        {
            myBet.choiceBet = AvailableChoice.MacAndCheese;
        } 
        else {
            myBet.choiceBet = AvailableChoice.Invalid;
        }
    }

    function TicketPrice() public view returns (uint256){
        (, int256 price, , , ) = ethUsdPriceFeed.latestRoundData();
        uint256 adjustedPrice = uint256(price) * 10**10; // 18 decimals
        uint256 costToEnter = (USDTicketPrice * 10**18)/adjustedPrice;
        return costToEnter;
    }

    function endGame() public {
        require(players.length > 1, "Must have at least 2 players");
        require( (block.timestamp - RoundStartTime) < (RoundDuration + RevealDuration), "Must wait to end game");
        game_state = GAME_STATE.CALCULATING_WINNER;
        bytes32 requestId = requestRandomness(keyhash, LinkFee);
        emit RequestedRandomness(requestId);
        emit GameState("Calculating winner");
    }

    function choiceWinnerForCurrentRound() public {
        require(
            game_state == GAME_STATE.REVEAL,
            "You aren't there yet!"
        );
        game_state = GAME_STATE.CHOOSEROUNDWINNER;
        bytes32 requestId = requestRandomness(keyhash, LinkFee);
        emit RequestedRandomness(requestId);
        emit GameState("Calculating winner");
        emit RoundEnded(1);
        emit RevealStarted(1);
    }

    function fulfillRandomness(bytes32, uint256 _randomness)
        internal
        override
    {
        require(
            game_state == GAME_STATE.CHOOSEROUNDWINNER,
            "You aren't there yet!"
        );
        require(_randomness > 0, "random-not-found");

        uint numberOfPlayers = players.length;
        uint256 indexOfWinner = _randomness % numberOfPlayers;
        uint256 winnderChoice = _randomness % uint256(AvailableChoice.Invalid);

        for (uint i=0; i < numberOfPlayers; i++)
        {
            if ((uint256)(bets[1][1][players[i]].choiceBet) == winnderChoice)
            {
                winningPlayers.push(players[i]);
            }
        }
        
        if (winningPlayers.length == 0)
        {
            blocksWon[players[indexOfWinner]] += 1;
        } else {
            uint award = (10*players.length)/winningPlayers.length;
            for (uint i=0; i < winningPlayers.length; i++)
            {
                blocksWon[winningPlayers[i]] += award;
            }
        }

        // Reset
        players = new address payable[](0);
        winningPlayers = new address payable[](0);

        if ( CurrentRound == TotalRounds)
        {
            // End the game
            game_state = GAME_STATE.CLOSED;
            randomness = _randomness;

            gameWinner = participants[0];
            uint256 highestBlocksWon = blocksWon[participants[0]];
            for (uint i = 1; i < participants.length; i++)
            {
                if (blocksWon[participants[i]] > highestBlocksWon) {
                    highestBlocksWon = blocksWon[participants[i]];
                    gameWinner = participants[i];
                }

            }
            
            gameWinner.transfer(GameWinningPool[1]);

            emit RevealEnded(CurrentRound);
            emit GameState("Closed");
            emit GameEdned(gameWinner);
        } 
        else
        {
            // start new round
            CurrentRound += 1;
            RoundStartTime = block.timestamp;
            game_state = GAME_STATE.OPEN;
            emit RoundStarted(CurrentRound);
        } 
        
    }

    function getLinkBalance() external view returns (uint256){
        return LINKTOKEN.balanceOf(address(this));
    }

    function withdrawEth() external onlyOwner{
        payable(msg.sender).transfer(address(this).balance);
    }

    function withdrawLINK(uint256 amount, address to) external onlyOwner {
        LINKTOKEN.transfer(to, amount);
    }
    function getContractBalance() external view returns(uint256){
        return address(this).balance;
    }
    function getNumberofPlayers() external view returns (uint256){
        return players.length;
    }

    function verifyString(
        string memory message,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public pure returns (address signer) {
        string memory header = "\x19Ethereum Signed Message:\n000000";
        uint256 lengthOffset;
        uint256 length;
        assembly {
            length := mload(message)
            lengthOffset := add(header, 57)
        }
        require(length <= 999999);
        uint256 lengthLength = 0;
        uint256 divisor = 100000;
        while (divisor != 0) {
            uint256 digit = length / divisor;
            if (digit == 0) {
                if (lengthLength == 0) {
                    divisor /= 10;
                    continue;
                }
            }
            lengthLength++;
            length -= digit * divisor;
            divisor /= 10;
            digit += 0x30;
            lengthOffset++;
            assembly {
                mstore8(lengthOffset, digit)
            }
        }
        if (lengthLength == 0) {
            lengthLength = 1 + 0x19 + 1;
        } else {
            lengthLength += 1 + 0x19;
        }
        assembly {
            mstore(header, lengthLength)
        }
        bytes32 check = keccak256(abi.encodePacked(header, message));
        return ecrecover(check, v, r, s);
    }

    function checkUpkeep(bytes calldata /* checkData */) external view returns (bool upkeepNeeded, bytes memory /* performData */) {
        upkeepNeeded = ( (game_state == GAME_STATE.OPEN && (block.timestamp - RoundStartTime) > RoundDuration)
                            || (game_state == GAME_STATE.REVEAL && (block.timestamp - RoundStartTime) > (RoundDuration + RevealDuration))
        );
        // We don't use the checkData in this example. The checkData is defined when the Upkeep was registered.
    }

    function performUpkeep(bytes calldata /* performData */) external {
        //We highly recommend revalidating the upkeep in the performUpkeep function
        if (game_state == GAME_STATE.OPEN && (block.timestamp - RoundStartTime) > RoundDuration ) {
            game_state = GAME_STATE.REVEAL;
        }

        if (game_state == GAME_STATE.REVEAL && (block.timestamp - RoundStartTime) > (RoundDuration + RevealDuration))
        {
            choiceWinnerForCurrentRound();
        }
    }

    function getRoundRemainingTime() external view returns (uint256){
        if (( RoundStartTime + RoundDuration) < block.timestamp) 
        {
            return 0;
        }
        return ( RoundStartTime + RoundDuration) - block.timestamp;
    }

    function getTimeToNextRound() external view returns (uint256){
        if (( RoundStartTime + RoundDuration + RevealDuration) < block.timestamp) 
        {
            return 0;
        }
        return ( RoundStartTime + RoundDuration + RevealDuration) - block.timestamp;
    }
}
