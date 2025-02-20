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

    uint public constant catchTimeout = 1 minutes; // TODO: change for production

    mapping(address => uint) public randomSeedBlocks;
    mapping(address => uint) public lastCatch;

    TheBugs public theBugs;

    event CatchInitiated(address indexed catcher, uint randomSeedBlock);

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

        require(lastCatch[catcher] + catchTimeout <= block.timestamp);

        uint randomSeedBlock = block.number + 1;
        randomSeedBlocks[catcher] = randomSeedBlock;
        lastCatch[catcher] = block.timestamp;

        emit CatchInitiated(catcher, randomSeedBlock);
    }

    function completeCatch(string calldata name) external {
        address catcher = _msgSender();

        uint tokenId = getCatchInProgressTokenId(catcher);
        theBugs.mint(catcher, tokenId, name);
    }

    function getCatchInProgressTokenId(address catcher) view public returns (uint) {
        bytes32 randomSeed = blockhash(randomSeedBlocks[catcher]);
        require(randomSeed != 0, "BugMinter: catch expired");

        return uint(keccak256(abi.encodePacked(randomSeed, catcher, address(this), address(theBugs))));
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyRole(UPGRADER_ROLE)
        override
    {}
}
