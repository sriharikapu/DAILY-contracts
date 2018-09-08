pragma solidity ^0.4.24;

import "./BouncerProxy.sol";
import "@optionality.io/clone-factory/contracts/CloneFactory.sol";


contract Factory is CloneFactory {

    address public libraryAddress;

    event Created(address newThingAddress);

    constructor() public {
        libraryAddress = new BouncerProxy();
    }

    function createThing(address _signer, address _recoverer) public {
        address clone = createClone(libraryAddress);
        BouncerProxy(clone).init(_signer, _recoverer);
        emit Created(clone);
    }

}
