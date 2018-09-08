pragma solidity ^0.4.24;

import "./openzeppelin/SignatureBouncer.sol";
import "./SignerWithDeadSwitch.sol";

// Inspired by https://github.com/austintgriffith/bouncer-proxy/blob/master/BouncerProxy/BouncerProxy.sol
contract BouncerProxy is SignatureBouncer, SignerWithDeadSwitch {

  constructor(address _signer) public {
      _addSigner(_signer);
  }

  // to avoid replay and to enfore tx order
  uint public nonce;

  function () public payable {
      emit Received(msg.sender, msg.value);
  }

  event Received (address indexed sender, uint value);

  // original forward function copied from https://github.com/uport-project/uport-identity/blob/develop/contracts/Proxy.sol
  function forward(bytes sig, address signer, address destination, uint value, bytes data) public {
      //the hash contains all of the information about the meta transaction to be called
      bytes32 _hash = keccak256(abi.encodePacked(address(this), signer, destination, value, data, nonce));
      nonce++;

      //this makes sure signer signed correctly AND signer is a valid bouncer
      require(_isValidDataHash(_hash,sig));

      //execute the transaction with all the given parameters
      require(executeCall(destination, value, data));
      emit Forwarded(sig, signer, destination, value, data, _hash);
  }

  // when some frontends see that a tx is made from a bouncerproxy, they may want to parse through these events to find out who the signer was etc
  event Forwarded (bytes sig, address signer, address destination, uint value, bytes data, bytes32 _hash);

  // copied from https://github.com/uport-project/uport-identity/blob/develop/contracts/Proxy.sol
  // which was copied from GnosisSafe
  // https://github.com/gnosis/gnosis-safe-contracts/blob/master/contracts/GnosisSafe.sol
  function executeCall(address to, uint256 value, bytes data) internal returns (bool success) {
    assembly {
       success := call(gas, to, value, add(data, 0x20), mload(data), 0, 0)
    }
  }
}

interface StandardToken {
  function transfer(address _to,uint256 _value) external returns (bool);
}
