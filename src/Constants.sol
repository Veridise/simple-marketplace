// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library Constants {
    uint256 public constant REGISTRATION_BONUS = 50;
    uint256 public constant SUCCESSFUL_PROJECT_BONUS = 10;
    uint256 public constant MINIMUM_AMOUNT_FOR_PROJECT_COST = 10000;
    uint256 public constant MAX_NO_OF_PROJECTS = 5;
    uint256 public constant MAX_NO_OF_FAILED_PROJECTS = 3;

    string public constant FREELANCER_ROLE = "F";
    string public constant PROJECT_MANAGER_ROLE = "PM";
}
