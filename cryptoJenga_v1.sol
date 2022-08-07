// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";



contract Lottery is VRFConsumerBase, Ownable {

    uint256 public USDTicketPrice;
    address payable[] players;
    address payable public recentWinner;
    uint256 public randomness;
    AggregatorV3Interface internal ethUsdPriceFeed;
    LinkTokenInterface LINKTOKEN;
    address link_token_contract = 0x01BE23585060835E02B77ef475b0Cc51aA1e0709;
    uint256 public RoundStartTime;


    enum LOTTERY_STATE {
        OPEN,
        CLOSED,
        CALCULATING_WINNER
    }
    //0
    //1
    //2
    LOTTERY_STATE public lottery_state;
    uint256 public LinkFee;
    bytes32 public keyhash;
    event RequestedRandomness(bytes32 requestId);

    constructor(
        address _priceFeedAddress,
        address _vrfCoordinator,
        uint256 _fee,
        bytes32 _keyhash
    ) VRFConsumerBase(_vrfCoordinator, link_token_contract){
        //$30
        USDTicketPrice = 30 * (10**18);
        ethUsdPriceFeed = AggregatorV3Interface(_priceFeedAddress);
        //* Network: Rinkeby
        //* Aggregator: ETH/USD
        //* _priceFeedAddress= 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        lottery_state = LOTTERY_STATE.CLOSED;
        LinkFee = _fee;
        keyhash = _keyhash;
        LINKTOKEN = LinkTokenInterface(link_token_contract);

        //fee = 0.1 * 10 **18 (0.1 Link)
        //vrfCoordinator = 0x6168499c0cFfCaCD319c818142124B7A15E857ab
        //keyHash = 0xd89b2bf150e3b9e13446986e571fb9cab24b13cea0a43ea20a6049a85cc807cc
        //1000000000000000000 = 1 LINK
        //100000000000000000 = fee (.1 LINK)

    }

    function bet() public payable {
        require(lottery_state==LOTTERY_STATE.OPEN);
        require(msg.value >= TicketPrice(), "Not enough ETH");
        require(block.timestamp - RoundStartTime < 15 minutes, "You are too late for this round");
        players.push(payable(msg.sender));
    }

    function TicketPrice() public view returns (uint256){
        (, int256 price, , , ) = ethUsdPriceFeed.latestRoundData();
        uint256 adjustedPrice = uint256(price) * 10**10; // 18 decimals
        uint256 costToEnter = (USDTicketPrice * 10**18)/adjustedPrice;
        return costToEnter;
    }

    function startLottery() public onlyOwner {
        require(lottery_state == LOTTERY_STATE.CLOSED, "Can't start a new lottery");
        lottery_state = LOTTERY_STATE.OPEN;
        RoundStartTime = block.timestamp;
    }

    function endLottery() public {
        require(players.length >= 1, "Must have more than 1 players");
        require(block.timestamp > RoundStartTime + 25 minutes, "Must wait");
        lottery_state = LOTTERY_STATE.CALCULATING_WINNER;
        bytes32 requestId = requestRandomness(keyhash, LinkFee);
        emit RequestedRandomness(requestId);
    }

    function fulfillRandomness(bytes32 _requestId, uint256 _randomness)
        internal
        override
    {
        require(
            lottery_state == LOTTERY_STATE.CALCULATING_WINNER,
            "You aren't there yet!"
        );
        require(_randomness > 0, "random-not-found");
        uint256 indexOfWinner = _randomness % players.length;
        recentWinner = players[indexOfWinner];
        recentWinner.transfer(address(this).balance * 90/100);
        // Reset
        players = new address payable[](0);
        lottery_state = LOTTERY_STATE.CLOSED;
        randomness = _randomness;
    }

    function getLinkBalance() external view returns (uint){
        return LINKTOKEN.balanceOf(address(this));
    }

    function withdraw() external onlyOwner{
        payable(msg.sender).transfer(address(this).balance);
    }

    function withdrawLINK(uint256 amount, address to) external onlyOwner {
        LINKTOKEN.transfer(to, amount);
    }

    function getContractBalance() external view returns(uint){
        return address(this).balance;
    }

}
