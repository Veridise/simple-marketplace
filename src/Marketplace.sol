// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Constants} from "./Constants.sol";
import {Strings} from "./Strings.sol";

contract Marketplace {
    address public marketplaceOwner;
    address public registrationDesk;

    constructor() {
        marketplaceOwner = msg.sender;
    }

    modifier onlyMarketplaceOwner() {
        require(msg.sender == marketplaceOwner);
        _;
    }

    // REGISTRATION DESK
    function setRegistrationDesk(address _registrationDesk) public onlyMarketplaceOwner {
        registrationDesk = _registrationDesk;
    }

    modifier onlyRegistrationDesk() {
        require(msg.sender == registrationDesk);
        _;
    }

    function isUserRegistered(address _user) public view onlyRegistrationDesk returns(bool) {
        return userRegistrations[_user];
    }

    function createUser(address _user, string memory _role) public onlyRegistrationDesk {
        User memory user;

        if (Strings.equal(_role, Constants.FREELANCER_ROLE)) {
            user.role = Role.FREELANCER;
            ranks[_user] += Constants.REGISTRATION_BONUS;
            freelancers[_user] = true;
        } else if (Strings.equal(_role, Constants.PROJECT_MANAGER_ROLE)) {
            user.role = Role.PROJECT_MANAGER;
            projectManagers[_user] = true;
        }

        users[_user] = user;
    }

    function submitUserRegistration(address _user) public onlyRegistrationDesk {
        userRegistrations[_user] = true;
    }

    // USERS
    enum Role { FREELANCER, PROJECT_MANAGER }

    struct User {
        Role role;
        uint256 no_of_successful_projects;
        uint256 no_of_unsuccessful_projects;
    }

    mapping(address => bool) public userRegistrations;
    mapping(address => User) public users;
    mapping(address => bool) public projectManagers;
    mapping(address => bool) public freelancers;
    mapping(address => bool) public blacklistedFreelancers;
    mapping(address => uint256) public ranks;
    mapping(address => mapping(uint256 => bool)) public collectedPayments;

    function isBlacklistedFreelancer(address _user) public view returns(bool) {
        return blacklistedFreelancers[_user];
    }

    function isFreelancer(address _user) public view returns(bool) {
        return freelancers[_user] && users[_user].role == Role.FREELANCER;
    }

    function isProjectManager(address _user) public view returns(bool) {
        return projectManagers[_user] && users[_user].role == Role.PROJECT_MANAGER;
    }

    function getRole(address _user) public view returns(Role) {
        return users[_user].role;
    }

    function getNoOfSuccessfulProjects(address _user) public view returns(uint256) {
        return users[_user].no_of_successful_projects;
    }

    function getNoOfUnsuccessfulProjects(address _user) public view returns(uint256) {
        return users[_user].no_of_successful_projects;
    }

    function getRank(address _user) public view returns(uint256) {
        return ranks[_user];
    }

    function getFreelancerRank(address _freelancer) public view returns(uint256) {
        uint256 rank = ranks[_freelancer];

        if (rank >= 0 && rank <= 100) {
            return 3;
        } else if (rank > 100 && rank <= 500) {
            return 2;
        } else {
            return 1;
        }
    }

    // PROJECTS
    enum Status { AVAILABLE, ONGOING, COMPLETED }

    struct Project {
        uint256 id;
        Status status;
        string requirements;
        uint256 experienceLevel;
        uint256 cost;
        address manager;
        address freelancer;
        address mediator;
        bool managerDecision;
        bool mediatorDecision;
    }

    uint256 public projectsCounter;
    mapping(uint256 => Project) public projects;
    mapping(address => mapping(uint256 => bool)) public projectDecisions; 

    function getManager(uint256 _id) public view returns(address) {
        return projects[_id].manager;
    }

    function getFreelancer(uint256 _id) public view returns(address) {
        return projects[_id].freelancer;
    }

    function getMediator(uint256 _id) public view returns(address) {
        return projects[_id].mediator;
    }

    function getStatus(uint256 _id) public view returns(Status) {
        return projects[_id].status;
    }

    function getCost(uint256 _id) public view returns(uint256) {
        return projects[_id].cost;
    }

    function getExperienceLevel(uint256 _id) public view returns(uint256) {
        return projects[_id].experienceLevel;
    }

    function submitProject(string memory _requirements, uint256 _experienceLevel) public payable returns(uint256) {
        require(msg.value >= Constants.MINIMUM_AMOUNT_FOR_PROJECT_COST, "Not sufficient funds to cover the cost.");
        require(projectsCounter <= Constants.MAX_NO_OF_PROJECTS - 1, "No more project submissions allowed.");

        Project memory project;
        project.id = projectsCounter;
        projectsCounter += 1;
        project.status = Status.AVAILABLE;
        project.requirements = _requirements;
        project.experienceLevel = _experienceLevel;
        project.cost = Constants.MINIMUM_AMOUNT_FOR_PROJECT_COST;
        project.manager = msg.sender;

        projects[project.id] = project;

        return project.id;
    }

    modifier projectIdIsValid(uint256 _id) {
        require(_id == 0 || _id < projectsCounter, "Invalid project id.");
        _;
    }

    function _statusMatches(uint256 _id, Status _status) internal view returns (bool) {
        return projects[_id].status == _status;
    }

    function joinProjectAsFreelancer(uint256 _id) public projectIdIsValid(_id) {
        require(_statusMatches(_id, Status.AVAILABLE), "The project is either ongoing or closed.");
        require(!blacklistedFreelancers[msg.sender], "Blacklisted users are not allowed to join projects.");

        require(projects[_id].freelancer == address(0) && users[msg.sender].role == Role.FREELANCER, "A freelancer already joined the project.");

        projects[_id].freelancer = msg.sender;
    }

    function joinProjectAsMediator(uint256 _id) public projectIdIsValid(_id) {
        require(_statusMatches(_id, Status.AVAILABLE), "The project is either ongoing or closed.");
        require(!blacklistedFreelancers[msg.sender], "Blacklisted users are not allowed to join projects.");

        require(projects[_id].mediator == address(0) && users[msg.sender].role == Role.FREELANCER, "A mediator already joined the project.");

        projects[_id].mediator = msg.sender;
    }

    function startProject(uint256 _id) public projectIdIsValid(_id) {
        require(_statusMatches(_id, Status.AVAILABLE), "The project is either ongoing or closed.");
        require(projects[_id].manager == msg.sender, "Only the PM can start the project.");
        require(projects[_id].freelancer != address(0) && projects[_id].mediator != address(0), "No one joined.");

        projects[_id].status = Status.ONGOING;
    }

    function submitSolution(uint256 _id) public projectIdIsValid(_id) {
        require(_statusMatches(_id, Status.ONGOING));
        require(projects[_id].freelancer == msg.sender, "Only the freelancer can submit the solution.");

        projects[_id].status = Status.COMPLETED;
    }

    function submitDecision(uint256 _id, bool _decision) public {
        require(projects[_id].manager == msg.sender || projects[_id].mediator == msg.sender, "Only the manager/mediator can submit the decision.");
        require(projects[_id].status == Status.COMPLETED);

        // Set to true when manager/mediator submits the decision for project with the id == _id
        projectDecisions[msg.sender][_id] = true;

        if (projects[_id].manager == msg.sender) {
            projects[_id].managerDecision = _decision;
        } else {
            projects[_id].mediatorDecision = _decision;
        }

        if (projects[_id].managerDecision && projectDecisions[projects[_id].manager][_id]) {
            // Increase number of successful projects for the freelancer
            users[projects[_id].freelancer].no_of_successful_projects += 1;
        }

        if (!projects[_id].managerDecision && projectDecisions[projects[_id].manager][_id]) {
            if (!projects[_id].mediatorDecision && projectDecisions[projects[_id].mediator][_id]) {
                // Increase number of unsuccessful projects for the freelancer
                users[projects[_id].freelancer].no_of_unsuccessful_projects += 1;

                if (users[projects[_id].freelancer].no_of_unsuccessful_projects == Constants.MAX_NO_OF_FAILED_PROJECTS) {
                    blacklistedFreelancers[projects[_id].freelancer] = true;
                }
            }
        }
    }

    function collectPayment(uint256 _id) public {
        _statusMatches(_id, Status.COMPLETED);
        require(
            projects[_id].freelancer == msg.sender ||
            projects[_id].mediator == msg.sender ||
            projects[_id].manager == msg.sender, "Only freelancer/mediator/manager can collect payment."
        );

        require(!collectedPayments[msg.sender][_id], "The user collected the payment already.");

        // Manager => NO
        if (!projects[_id].managerDecision && projectDecisions[projects[_id].manager][_id]) {
            // Mediator => NO
            if (!projects[_id].mediatorDecision && projectDecisions[projects[_id].mediator][_id]) {
                if (msg.sender == projects[_id].manager) {
                    bool sent_pm = payable(msg.sender).send(projects[_id].cost * 80 / 100);
                    collectedPayments[msg.sender][_id] = true;
                    require(sent_pm, "Failed to send funds to manager.");
                } else if (msg.sender == projects[_id].mediator) {
                    collectedPayments[msg.sender][_id] = true;
                    bool sent_m = payable(projects[_id].mediator).send(projects[_id].cost * 15 / 100);
                    require(sent_m, "Failed to send funds to mediator.");
                }
            // Mediator => YES
            } else if (projects[_id].mediatorDecision && projectDecisions[projects[_id].mediator][_id]) {
                if (msg.sender == projects[_id].freelancer) {
                    collectedPayments[msg.sender][_id] = true;
                    bool sent_f = payable(projects[_id].freelancer).send(projects[_id].cost * 80 / 100);
                    require(sent_f, "Failed to send funds to freelancer.");
                } else if (msg.sender == projects[_id].mediator) {
                    collectedPayments[msg.sender][_id] = true;
                    bool sent_m = payable(projects[_id].mediator).send(projects[_id].cost * 15 / 100);
                    require(sent_m, "Failed to send funds to mediator.");
                }
            }
        // Manager => YES
        } else if (projects[_id].managerDecision && projectDecisions[projects[_id].manager][_id]) {
            if (msg.sender == projects[_id].freelancer) {
                collectedPayments[msg.sender][_id] = true;
                bool sent_f = payable(projects[_id].freelancer).send(projects[_id].cost * 90 / 100);
                require(sent_f, "Failed to send funds to freelancer.");
            }
            if (msg.sender == projects[_id].mediator) {
                collectedPayments[msg.sender][_id] = true;
                bool sent_m = payable(projects[_id].mediator).send(projects[_id].cost * 5 / 100);
                require(sent_m, "Failed to send funds to mediator.");
            }
        }
    }

}
