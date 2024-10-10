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
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    uint public constant catchTimeout = 1 days;

    mapping(address => uint) public randomSeedBlocks;
    mapping(address => uint) public lastCatch;

    TheBugs public theBugs;

    event CatchInitiated(address catcher, uint randomSeedBlock);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(address theBugs_) initializer public {
        __AccessControl_init();
        __AccessControlEnumerable_init();
        __UUPSUpgradeable_init();

        theBugs = TheBugs(theBugs_);

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function initiateCatch() external {
        address catcher = _msgSender();
        uint prevrandomSeedBlock = randomSeedBlocks[catcher];

        require(lastCatch[catcher] + catchTimeout <= block.timestamp);
        require(
            prevrandomSeedBlock == 0 || blockhash(prevrandomSeedBlock) == 0,
            "BugMinter: catch is already in the process"
        );

        uint randomSeedBlock = block.number + 1;
        randomSeedBlocks[catcher] = randomSeedBlock;

        emit CatchInitiated(catcher, randomSeedBlock);
    }

    function completeCatch() external {
        address catcher = _msgSender();
        bytes32 randomSeed = blockhash(randomSeedBlocks[catcher]);

        randomSeedBlocks[catcher] = 0;
        lastCatch[catcher] = block.timestamp;

        uint tokenId = uint(keccak256(abi.encodePacked(randomSeed, catcher, address(this), address(theBugs))));
        theBugs.safeMint(catcher, tokenId);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyRole(UPGRADER_ROLE)
        override
    {}
}
