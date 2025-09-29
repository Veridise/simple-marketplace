// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {Marketplace} from "../src/Marketplace.sol";
import {RegistrationDesk} from "../src/RegistrationDesk.sol";

contract OrCaDeploymentScript is Script {
    Marketplace public marketplace;
    RegistrationDesk public registrationDesk;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        marketplace = new Marketplace();
        registrationDesk = new RegistrationDesk(address(marketplace));

        marketplace.setRegistrationDesk(address(registrationDesk));

        vm.stopBroadcast();
    }
}
