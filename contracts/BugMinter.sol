// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/extensions/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "./TheBugs.sol";

contract BugMinter is
    Initializable,
    AccessControlEnumerableUpgradeable,
    UUPSUpgradeable
{
    struct CatchInProgressData {
        uint128 randomSeedBlock;
        bool premium;
    }

    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    uint public constant CATCH_TIMEOUT = 1 minutes; // TODO: change for production
    uint public constant PREMIUM_CATCH_PRICE = 0.001 ether; // TODO: change for production

    mapping(address => CatchInProgressData) public catchesInProgress;
    mapping(address => uint) public lastFreeCatchTimestamps;

    TheBugs public theBugs;
    uint public lastCatchedBug;
    address paymentReceiver;

    event CatchInitiated(address indexed catcher, uint randomSeedBlock, bool premium);
    event CatchCompleted(address indexed catcher, uint tokenId);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(address theBugs_, address paymentReceiver_) initializer public {
        __AccessControl_init();
        __AccessControlEnumerable_init();
        __UUPSUpgradeable_init();

        theBugs = TheBugs(theBugs_);
        paymentReceiver = paymentReceiver_;

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function initiateFreeCatch() external {
        address catcher = _msgSender();

        require(lastFreeCatchTimestamps[catcher] + CATCH_TIMEOUT <= block.timestamp);

        _initiateCatch(catcher, false);
    }

    function initiatePremiumCatch() external payable {
        address catcher = _msgSender();

        require(msg.value == PREMIUM_CATCH_PRICE);

        _initiateCatch(catcher, true);
    }

    function completeCatch(string calldata name) external {
        address catcher = _msgSender();

        uint tokenId = getCatchInProgressTokenId(catcher);
        theBugs.mint(catcher, tokenId, name);
        delete catchesInProgress[catcher];

        lastCatchedBug = tokenId;

        emit CatchCompleted(catcher, tokenId);
    }

    function getCatchInProgressTokenId(address catcher) view public returns (uint) {
        CatchInProgressData storage catchInProgress = catchesInProgress[catcher];
        bytes32 randomSeed = blockhash(catchInProgress.randomSeedBlock);
        require(randomSeed != 0, "BugMinter: catch expired");

        uint idPremiumFlag = catchInProgress.premium ? 1 : 0 << 255;
        uint idRandom = uint(keccak256(abi.encodePacked(
            randomSeed, catcher, address(this), address(theBugs)
        ))) >> 1;

        return idPremiumFlag + idRandom;
    }

    function _initiateCatch(address catcher, bool premium) private {
        uint128 randomSeedBlock = uint128(block.number + 1);
        catchesInProgress[catcher] = CatchInProgressData(randomSeedBlock, premium);
        if (!premium) {
            lastFreeCatchTimestamps[catcher] = block.timestamp;
        }

        emit CatchInitiated(catcher, randomSeedBlock, premium);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyRole(UPGRADER_ROLE)
        override
    {}
}
