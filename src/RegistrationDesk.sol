// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Marketplace} from "./Marketplace.sol";
import {Constants} from "./Constants.sol";

contract RegistrationDesk {
    Marketplace marketplace;

    constructor(address _marketplaceAddress) {
        marketplace = Marketplace(_marketplaceAddress);
    }

    function register(string memory _role) internal {
        require(!marketplace.isUserRegistered(msg.sender), "User already registered.");

        marketplace.createUser(msg.sender, _role);
    }

    function registerAsFreelancer() public {
        require(!marketplace.isProjectManager(msg.sender), "Only one role per user.");
        register(Constants.FREELANCER_ROLE);
    }

    function registerAsProjectManager() public {
        require(!marketplace.isFreelancer(msg.sender), "Only one role per user.");
        require(!marketplace.isProjectManager(msg.sender), "Already registered as PM.");
        register(Constants.PROJECT_MANAGER_ROLE);
    }
}
