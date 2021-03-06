/*
Copyright 2018 Keochain

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
 */

pragma solidity 0.4.24;
import "openzeppelin-solidity/contracts/token/ERC20/StandardToken.sol";
import "./CustomPausable.sol";
import "openzeppelin-solidity/contracts/ownership/NoOwner.sol";
import "openzeppelin-solidity/contracts/token/ERC20/BurnableToken.sol";

///@title Keochain Token
///@author Binod Nirvan, Subramanian Venkatesan (http://keochain.io)
///@notice Keochain (KEO) is the utility token of the Keochain ecosystem.
///Keochain (KEO) will be distributed through a public ICO. A small portion of
///Keochain (KEO) will be distributed for free for gamification purposes, rewarding a long-term investor
///mindset and engagement in the Keochain App.
///Keochain provides gamification of crypto investments to
///reward long term thinking and provide benchmarks along the way. Holding crypto assets long
///term requires patience and endurance. It’s easy to fall into traps when there are pumps or dips.
///With gamification users can both be educated about the upsides of staying out of the game of
///quick returns and provided some of the same emotional thrills that trading gives.
contract KeochainToken is CustomPausable, StandardToken, BurnableToken, NoOwner {
  string public constant name = "Keochain";
  string public constant symbol = "KEO";
  uint8 public constant decimals = 18;
  uint256 public constant INITIAL_SUPPLY = 1000000000 * (10 ** uint256(decimals));

  uint256 public constant GAMIFICATION_TOKEN_ALLOCATION_PER_DAY = 30000 * (10 ** uint256(decimals));
  uint256 public totalRewarded = 0;
  uint256 public rewardBeganSince;
  address public gamificationWallet;
  bool public released;


  event Mint(address indexed to, uint256 amount);

  modifier canTransfer(address _sender) {
    if(paused) {
      if(!whitelist[_sender]) {
        revert();
      }
    } else if(!released) {
      if(!whitelist[_sender]) {
        revert();
      }
    }
    _;
  }

  ///@param	_gamificationWallet The wallet address used for the gamification feature.
  ///@dev Set "rewardBeganSince" as a constant during deployment and remove this comment.
  constructor(address _gamificationWallet) public {
    require(_gamificationWallet != address(0));
    require(_gamificationWallet != msg.sender);

    gamificationWallet = _gamificationWallet;
    super.addAddressToWhitelist(_gamificationWallet);

    rewardBeganSince = now;

    totalSupply_ = INITIAL_SUPPLY;
    balances[msg.sender] = INITIAL_SUPPLY;

    emit Transfer(address(0), msg.sender, INITIAL_SUPPLY);
  }

  ///@notice Mints the specified amount of tokens.
  ///@param _to The address which will receive the minted tokens.
  ///@param _amount The amount of tokens to be minted.
  function mint(address _to, uint256 _amount) private {
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);

    emit Mint(_to, _amount);
  }

  function releaseTokenTransfer() public onlyWhitelisted {
    if(released) {
      revert();
    }
    released = true;
  }
  ///@return The total number of Keochain (KEO) in existence.
  function countTokensInExistence() public constant returns(uint256) {
    return INITIAL_SUPPLY.add(totalRewarded);
  }

  ///@notice This feature is used by Keochain gamification engine to provide daily rewards to the community.
  ///Please refer to the whitepaper for more information.
  ///@return The total number of tokens that should have been minted by the gamification engine.
  function getMintingSupply() public constant returns(uint256) {
    uint256 diff = now - rewardBeganSince;
    uint256 supply = diff.div(1 days).mul(GAMIFICATION_TOKEN_ALLOCATION_PER_DAY);
    return supply;
  }

  ///@notice Mints tokens for gamification engine.
  ///Every day, 30000 new Keochain (KEO) are minted for gamification purposes.
  ///They are distributed to active users as rewards in the gamification
  ///engine. The minting of new tokens amounts to an inflation of around 1.095% per annum
  ///based on the initial supply of 1 billion tokens.
  function mint() public whenNotPaused onlyWhitelisted {
    require(now > rewardBeganSince);

    uint256 mintingSupply = getMintingSupply();
    uint256 reward = mintingSupply.sub(totalRewarded);

    if(reward > 0) {
      mint(gamificationWallet, reward);
      totalRewarded = totalRewarded.add(reward);
    }
  }

  ///@notice Changes the destination wallet address of the gamification engine to receive the minted coins.
  ///@param _newWallet The address of the new gamification wallet to set.
  ///@param _removeExistingFromWhitelist Removes the existing gamification wallet from the whitelist.
  ///@dev Can only be performed by the whitelist.
  function changeGamificationWallet(address _newWallet, bool _removeExistingFromWhitelist) public whenNotPaused onlyWhitelisted {
    require(_newWallet != address(0));
    require(_newWallet != gamificationWallet);
    require(_newWallet != owner);

    if(_removeExistingFromWhitelist){
      removeAddressFromWhitelist(gamificationWallet);
    }

    addAddressToWhitelist(_newWallet);

    gamificationWallet = _newWallet;
  }

  ///@dev This function is overriden to leverage Pausable feature.
  function transferFrom(address _from, address _to, uint256 _value) canTransfer(_from) public returns (bool) {
    require(_to != address(0));
    return super.transferFrom(_from, _to, _value);
  }

  ///@dev This function is overriden to leverage Pausable feature.
  function approve(address _spender, uint256 _value) public canTransfer(msg.sender) returns (bool) {
    require(_spender != address(0));
    return super.approve(_spender, _value);
  }


  ///@dev This function is overriden to leverage Pausable feature.
  function increaseApproval(address _spender,uint256 _addedValue) public canTransfer(msg.sender) returns(bool) {
    require(_spender != address(0));
    return super.increaseApproval(_spender, _addedValue);
  }

  ///@dev This function is overriden to leverage Pausable feature.
  function decreaseApproval(address _spender, uint256 _subtractedValue) public canTransfer(msg.sender) whenNotPaused returns (bool) {
    require(_spender != address(0));
    return super.decreaseApproval(_spender, _subtractedValue);
  }

  ///@dev This function is overriden to leverage Pausable feature.
  function transfer(address _to, uint256 _value) public canTransfer(msg.sender) returns (bool) {
    require(_to != address(0));
    return super.transfer(_to, _value);
  }

  ///@notice Returns the sum of supplied values.
  ///@param _values The collection of values to create the sum from.
  function sumOf(uint256[] _values) private pure returns(uint256) {
    uint256 total = 0;

    for (uint256 i = 0; i < _values.length; i++) {
      total = total.add(_values[i]);
    }

    return total;
  }

  ///@notice Allows admins and/or whitelist to perform bulk transfer operation.
  ///@param _destinations The destination wallet addresses to send funds to.
  ///@param _amounts The respective amount of fund to send to the specified addresses.
  function bulkTransfer(address[] _destinations, uint256[] _amounts) public onlyWhitelisted {
    require(_destinations.length == _amounts.length);

    //Saving gas by determining if the sender has enough balance
    //to post this transaction.
    uint256 requiredBalance = sumOf(_amounts);
    require(balances[msg.sender] >= requiredBalance);

    for (uint256 i = 0; i < _destinations.length; i++) {
     transfer(_destinations[i], _amounts[i]);
   }
 }

  ///@notice Burns the coins held by the sender.
  ///@param _value The amount of coins to burn.
  ///@dev This function is overriden to leverage Pausable feature.
  function burn(uint256 _value) public whenNotPaused onlyWhitelisted {
    super.burn(_value);
  }
}
