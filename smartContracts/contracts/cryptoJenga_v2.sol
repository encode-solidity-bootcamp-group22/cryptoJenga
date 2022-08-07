// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";



contract cryptoJenga is VRFConsumerBase, Ownable {

    uint256 public USDTicketPrice;
    address payable[] players;
    address payable public recentWinner;
    uint256 public randomness;
    AggregatorV3Interface internal ethUsdPriceFeed;
    LinkTokenInterface LINKTOKEN;
    address link_token_contract = 0x01BE23585060835E02B77ef475b0Cc51aA1e0709;
    uint256 public RoundStartTime;


    enum GAME_STATE {
        OPEN,
        CLOSED,
        CALCULATING_WINNER
    }
    //0
    //1
    //2
    GAME_STATE public game_state;
    uint256 public LinkFee;
    bytes32 public keyhash;
    event RequestedRandomness(bytes32 requestId);
    event BetMade(address _player, uint256 _EthTicketPrice);
    event GameState(string _currentState);

    constructor(
        address _priceFeedAddress,
        address _vrfCoordinator,
        uint256 _fee,
        bytes32 _keyhash,
        uint256 _USDTicketPrice
    ) VRFConsumerBase(_vrfCoordinator, link_token_contract){
        USDTicketPrice = _USDTicketPrice;
        ethUsdPriceFeed = AggregatorV3Interface(_priceFeedAddress);
        //* Network: Rinkeby
        //* Aggregator: ETH/USD
        //* _priceFeedAddress= 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        game_state = GAME_STATE.CLOSED;
        LinkFee = _fee;
        keyhash = _keyhash;
        LINKTOKEN = LinkTokenInterface(link_token_contract);

        //fee = 100000000000000000 (0.1 Link) 
        //US TicketPrice = 30000000000000000000 ($30)
        //vrfCoordinator = 0xb3dCcb4Cf7a26f6cf6B120Cf5A73875B7BBc655B
        //keyHash = 0x2ed0feb3e7fd2022120aa84fab1945545a9f2ffc9076fd6156fa96eaff4c1311

    }
    function bet() public payable {
        require(game_state==GAME_STATE.OPEN);
        require(msg.value >= TicketPrice(), "Not enough ETH");
        require(block.timestamp - RoundStartTime < 3 minutes, "You are too late for this round");
        players.push(payable(msg.sender));
        emit BetMade(msg.sender, msg.value);
    }

    function TicketPrice() public view returns (uint256){
        (, int256 price, , , ) = ethUsdPriceFeed.latestRoundData();
        uint256 adjustedPrice = uint256(price) * 10**10; // 18 decimals
        uint256 costToEnter = (USDTicketPrice * 10**18)/adjustedPrice;
        return costToEnter;
    }

    function startGame() public onlyOwner {
        require(game_state == GAME_STATE.CLOSED, "Can't start a new game");
        game_state = GAME_STATE.OPEN;
        RoundStartTime = block.timestamp;
        emit GameState("Open");
    }

    function endGame() public {
        require(players.length > 1, "Must have at least 2 players");
        require(block.timestamp > RoundStartTime + 6 minutes, "Must wait to end game");
        game_state = GAME_STATE.CALCULATING_WINNER;
        bytes32 requestId = requestRandomness(keyhash, LinkFee);
        emit RequestedRandomness(requestId);
        emit GameState("Calculating winner");
    }

    function fulfillRandomness(bytes32, uint256 _randomness)
        internal
        override
    {
        require(
            game_state == GAME_STATE.CALCULATING_WINNER,
            "You aren't there yet!"
        );
        require(_randomness > 0, "random-not-found");
        uint256 indexOfWinner = _randomness % players.length;
        recentWinner = players[indexOfWinner];
        recentWinner.transfer(address(this).balance * 90/100);
        // Reset
        players = new address payable[](0);
        game_state = GAME_STATE.CLOSED;
        randomness = _randomness;
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

}
