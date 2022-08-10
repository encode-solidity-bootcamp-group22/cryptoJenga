// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";



contract cryptoJengav3 is VRFConsumerBase, Ownable {

    uint256 public USDTicketPrice;
    address payable[] players;
    address payable public recentWinner;
    uint256 public randomness;
    AggregatorV3Interface internal ethUsdPriceFeed;
    LinkTokenInterface LINKTOKEN;
    address link_token_contract = 0x01BE23585060835E02B77ef475b0Cc51aA1e0709;
    uint256 public RoundStartTime;
    uint256 RoundDuration; // in seconds
    uint256 RevealDuration; // in seconds

    using ECDSA for bytes32;
    mapping(uint256 => mapping(uint256 => mapping ( address => bool))) placedBet; 
    mapping(uint256 => mapping(uint256 => mapping ( address => Bet))) bets; //bets[gameId][roundNumber][playerAddress]

    struct Bet {
        uint256 betAmount;
        Signature betSignature;
        AvailableChoice bet;
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

    constructor(
        address _priceFeedAddress,
        address _vrfCoordinator,
        uint256 _fee,
        bytes32 _keyhash,
        uint256 _USDTicketPrice,
        uint256 _RoundDuration,
        uint256 _RevealDuration
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

        RoundDuration = _RoundDuration;
        RevealDuration = _RevealDuration;

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
        bytes32 _s,
        uint256 betAmount
    ) public payable {
        require(game_state==GAME_STATE.OPEN);
        require(betAmount >= TicketPrice(), "Not enough ETH");
        require( (block.timestamp - RoundStartTime) < RoundDuration, "You are too late for this round");
        require(placedBet[gameId][roundNumber][msg.sender] == false, "You already place bet in this round");

        placedBet[gameId][roundNumber][msg.sender] = true;
        bets[gameId][roundNumber][msg.sender] = Bet({betAmount: msg.value, betSignature: Signature({v: _v, r: _r, s: _s}), betString: ""});

        players.push(payable(msg.sender));
        emit BetMade(msg.sender, betAmount);
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
            myBet.bet = AvailableChoice.Pizza;
        } 
        else if (keccak256(abi.encodePacked((betString))) == keccak256(abi.encodePacked(("Cake"))))
        {
            myBet.bet = AvailableChoice.Cake;
        }
        else if (keccak256(abi.encodePacked((betString))) == keccak256(abi.encodePacked(("Sandwich"))))
        {
            myBet.bet = AvailableChoice.Sandwich;
        }
        else if (keccak256(abi.encodePacked((betString))) == keccak256(abi.encodePacked(("Sausage"))))
        {
            myBet.bet = AvailableChoice.Sausage;
        }
        else if (keccak256(abi.encodePacked((betString))) == keccak256(abi.encodePacked(("Pancake"))))
        {
            myBet.bet = AvailableChoice.Pancake;
        }
        else if (keccak256(abi.encodePacked((betString))) == keccak256(abi.encodePacked(("HotDog"))))
        {
            myBet.bet = AvailableChoice.HotDog;
        }
        else if (keccak256(abi.encodePacked((betString))) == keccak256(abi.encodePacked(("MacAndCheese"))))
        {
            myBet.bet = AvailableChoice.MacAndCheese;
        } 
        else {
            myBet.bet = AvailableChoice.Invalid;
        }
    }

    function TicketPrice() public view returns (uint256){
        (, int256 price, , , ) = ethUsdPriceFeed.latestRoundData();
        uint256 adjustedPrice = uint256(price) * 10**10; // 18 decimals
        uint256 costToEnter = (USDTicketPrice * 10**18)/adjustedPrice;
        return costToEnter;
    }

    function startGame() public onlyOwner {
        require(game_state == GAME_STATE.INITIALIZED, "Can't start a new game");
        game_state = GAME_STATE.OPEN;
        RoundStartTime = block.timestamp;
        emit GameState("Open");
        emit RoundStarted(1);
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
        uint256 indexOfWinner = _randomness % players.length;
        uint256 winnderChoice = _randomness % uint256(AvailableChoice.Invalid);
        recentWinner = players[indexOfWinner];
        recentWinner.transfer(address(this).balance * 90/100);
        // Reset
        players = new address payable[](0);
        game_state = GAME_STATE.CLOSED;
        randomness = _randomness;
        emit RevealEnded(1);
        emit GameState("Closed");
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
}
