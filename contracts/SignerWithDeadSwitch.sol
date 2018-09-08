pragma solidity ^0.4.24;

import "./openzeppelin/SignerRole.sol";
import "./openzeppelin/ECDSA.sol";

contract SignerWithDeadSwitch is SignerRole {
    using ECDSA for bytes32;

    address private recoverer;
    uint    private finalizeAfter;

    constructor(address _recoverer) public {
        recoverer = _recoverer;
    }

    function initiateDeadSwitch(uint _finalizeAfter, bytes _recovererSig) public {
        require(_finalizeAfter > now + 6 * 30 days);
        require(recoverer == keccak256(abi.encodePacked(_finalizeAfter)).recover(_recovererSig));
        finalizeAfter = _finalizeAfter;
    }

    function finalizeDeadSwitch(address _newSigner, bytes _recovererSig) public {
        require(finalizeAfter > 0);
        require(now > finalizeAfter);

        require(recoverer == keccak256(abi.encodePacked(_newSigner, finalizeAfter)).recover(_recovererSig));
        _addSigner(_newSigner);
        finalizeAfter = 0;
    }

    // this cancels a pending dead switch
    // NOTE: to be called by the contract itself!
    function changeRecoverer(address _newRecoverer) public {
        require(msg.sender == address(this));
        require(_newRecoverer != recoverer); // to avoid malicious initiateDeadSwitch() calls via sig replay
        recoverer = _newRecoverer;
        finalizeAfter = 0;
    }

}
