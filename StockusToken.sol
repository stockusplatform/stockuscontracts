pragma solidity ^0.4.13;

import "./StandardToken.sol";
import "./Ownable.sol";

/**
 * @title Stockus Token
 *
 * @dev StandardToken Ownable ERC20 Burnable token
 */
contract StockusToken is StandardToken, Ownable {

  string public constant name = "Stockus Token";
  string public constant symbol = "STT";
  uint8 public constant decimals = 18;
  uint public constant INITIAL_SUPPLY = 15000000;

  /* The finalizer contract that allows unlift the transfer limits on this token */
  address public releaseAgent;

  /** A crowdsale contract can release us to the wild if ICO success. If false we are are in transfer lock up period.*/
  bool public released = false;

  /** Map of agents that are allowed to transfer tokens regardless of the lock down period. These are crowdsale contracts and possible the team multisig itself. */
  mapping (address => bool) public transferAgents;

  /**
   * Limit token transfer until the crowdsale is over.
   *
   */
  modifier canTransfer(address _sender) {
    require(released || transferAgents[_sender]);
    _;
  }

  /** The function can be called only before or after the tokens have been releasesd */
  modifier inReleaseState(bool releaseState) {
    require(releaseState == released);
    _;
  }

  /** The function can be called only by a whitelisted release agent. */
  modifier onlyReleaseAgent() {
    require(msg.sender == releaseAgent);
    _;
  }


  /**
   * @dev Contructor that gives msg.sender all of existing tokens.
   */
  function StockusToken() public {
    totalSupply = INITIAL_SUPPLY;
    balances[msg.sender] = INITIAL_SUPPLY;
  }


  /**
   * Set the contract that can call release and make the token transferable.
   *
   * Design choice. Allow reset the release agent to fix fat finger mistakes.
   */
  function setReleaseAgent(address addr) onlyOwner inReleaseState(false) public {
    require(addr != 0x0);

    // We don't do interface check here as we might want to a normal wallet address to act as a release agent
    releaseAgent = addr;
  }

  function release() onlyReleaseAgent inReleaseState(false) public {
    released = true;
  }

  /**
   * Owner can allow a particular address (a crowdsale contract) to transfer tokens despite the lock up period.
   */
  function setTransferAgent(address addr, bool state) onlyOwner inReleaseState(false) public {
    require(addr != 0x0);
    transferAgents[addr] = state;
  }

  function transfer(address _to, uint _value) public canTransfer(msg.sender) returns (bool success) {
    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint _value) public canTransfer(_from) returns (bool success) {
    return super.transferFrom(_from, _to, _value);
  }

  event Burn(address indexed burner, uint256 value);

  /**
  * @dev Burns a specific amount of tokens from the issuing contract.
  * @param _value The amount of token to be burned.
  */
  function burn(uint _value) public onlyOwner {
      require(_value > 0);
      require(_value <= balances[msg.sender]);
      address burner = msg.sender;
      balances[burner] = balances[burner].sub(_value);
      totalSupply = totalSupply.sub(_value);
      Burn(burner, _value);
  }
}