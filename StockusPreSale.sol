pragma solidity ^0.4.13;


import "./Pausable.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./StockusToken.sol";


contract StockusPreSale is Pausable {
  using SafeMath for uint;

  string public constant name = "Stockus Token PreSale";

  StockusToken public token;

  address public beneficiary;

  uint public hardCap = (1250).mul(1 ether);

  uint public softCap = (150).mul(1 ether);


  uint public start_price = 2000;
//we will change the price when the threshold is broken
  uint public collection_threshold = (250).mul(1 ether);
  
  uint public final_price = 1500;

//maximum number of tokens to purchase for single user
  uint public purchaseLimit = 100000;

  uint public collected = 0;

  uint public tokensSold = 0;

  uint public investorCount = 0;

  uint public weiRefunded = 0;

  uint public startBlock;

  uint public endBlock;

  bool public softCapReached = false;

  bool public crowdsaleFinished = false;

  mapping (address => bool) refunded;

  event SoftCapReached(uint softCap);

  event ThresholdReached(uint collection_threshold);

  event NewContribution(address indexed holder, uint tokenAmount, uint etherAmount);

  event Refunded(address indexed holder, uint amount);

  modifier preSaleActive() {
    require(block.number >= startBlock && block.number < endBlock);
    _;
  }

  modifier preSaleEnded() {
    require(block.number >= endBlock);
    _;
  }

  function StockusTokenPreSale(
    address _token,
    address _beneficiary,
    uint _startBlock,
    uint _endBlock
  ) 
  {
    token = StockusToken(_token);
    beneficiary = _beneficiary;

    startBlock = _startBlock;
    endBlock = _endBlock;
  }

  function() payable {
    require(msg.value >= 0.01* 1 ether);
    doPurchase(msg.sender);
  }

  function refund() external preSaleEnded whenNotPaused {
    require(softCapReached == false);
    require(refunded[msg.sender] == false);

    uint balance = token.balanceOf(msg.sender);
    require(balance > 0);

    uint refund = balance.div(price);
    if (refund > this.balance) {
      refund = this.balance;
    }

    msg.sender.transfer(refund);
    refunded[msg.sender] = true;
    weiRefunded = weiRefunded.add(refund);
    Refunded(msg.sender, refund);
  }

  //withdraw collected Ethereum to the beneficiary 
  //only if soft cap is reached
  function withdraw() external onlyOwner {
    require(softCapReached);
    beneficiary.transfer(collected);
    token.transfer(beneficiary, token.balanceOf(this));
    crowdsaleFinished = true;
  }

  function doPurchase(address _owner) private preSaleActive whenNotPaused {
    require(!crowdsaleFinished);
    require(collected.add(msg.value) <= hardCap);

    if (!softCapReached && collected < softCap && collected.add(msg.value) >= softCap) {
      softCapReached = true;
      SoftCapReached(softCap);
    }
    uint tokens;
    if (collected < collection_threshold) {
        if (collected.add(msg.value) >= collection_threshold){
            tokens = collection_threshold.sub(collected).mul(start_price) + 
                     collection_threshold.add(msg.value).sub(collection_threshold).mul(start_price);
            ThresholdReached(collection_threshold);
        }
        else{
            tokens = msg.value.mul(start_price);
        }
    }
    else{
        tokens = msg.value.mul(final_price);
    }
    require(token.balanceOf(msg.sender).add(tokens) <= purchaseLimit);

    if (token.balanceOf(msg.sender) == 0) investorCount++;

    collected = collected.add(msg.value);

    token.transfer(msg.sender, tokens);

    tokensSold = tokensSold.add(tokens);

    NewContribution(_owner, tokens, msg.value);
  }
}