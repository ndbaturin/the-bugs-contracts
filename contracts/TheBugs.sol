// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/extensions/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

contract TheBugs is
    Initializable,
    AccessControlEnumerableUpgradeable,
    ERC721EnumerableUpgradeable,
    UUPSUpgradeable
{
    using Strings for uint;

    enum Rarity { COMMON, UNCOMMON, RARE, EPIC, LEGENDARY }

    struct Stats {
        uint8 intelligence;
        uint8 nimbleness;
        uint8 strength;
        uint8 endurance;
        uint8 charisma;
        uint8 talent;
    }

    struct SpeciesData {
        string name;
        string description;
        string image;
        Stats baseStats;
    }

    struct BugData {
        string name;
        Stats stats;
    }

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant DATA_SETTER_ROLE = keccak256("DATA_SETTER_ROLE");
    bytes32 public constant COMPETITION_ROLE = keccak256("COMPETITION_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    uint public constant SPECIES_COUNT = 3; // TODO: change

    mapping(uint => SpeciesData) public speciesDatas;
    mapping(uint => BugData) public bugDatas;

    mapping(uint => uint) public wins;
    mapping(uint => uint) public losses;
    mapping(uint => uint) public draws;

    uint private constant ATTRIBUTES_COUNT = 6;
    uint private constant BASE_ATTRIBUTES_TOTAL = 25;
    uint private constant PRECISION = 10000;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize() initializer public {
        __AccessControl_init();
        __AccessControlEnumerable_init();
        __ERC721_init("The Bugs", "BUGS");
        __ERC721Enumerable_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(DATA_SETTER_ROLE, msg.sender);
    }

    function mint(address to, uint tokenId, string calldata name) external onlyRole(MINTER_ROLE) {
        _initBugData(tokenId, name);
        _safeMint(to, tokenId);
    }

    function setSpeciesData(
        uint speciesID,
        SpeciesData calldata speciesData
    ) external onlyRole(DATA_SETTER_ROLE) {
        require(speciesID < SPECIES_COUNT, "TheBugs: invalid spesies ID");
        Stats calldata baseStats = speciesData.baseStats;
        require(
            baseStats.intelligence + baseStats.nimbleness + baseStats.strength +
                baseStats.endurance + baseStats.charisma + baseStats.talent ==
                25,
            "The Bugs: invalid base stats total"
        );

        speciesDatas[speciesID] = speciesData;
    }

    function incrementWins(uint tokenId) external onlyRole(COMPETITION_ROLE) {
        wins[tokenId]++;
    }

    function incrementLosses(uint tokenId) external onlyRole(COMPETITION_ROLE) {
        losses[tokenId]++;
    }

    function incrementDraws(uint tokenId) external onlyRole(COMPETITION_ROLE) {
        draws[tokenId]++;
    }
	
	function tokenURI(uint256 tokenId) public view override returns (string memory) { 
        SpeciesData memory species = getSpeciesData(tokenId);
        BugData storage bug = bugDatas[tokenId];

        string memory name;
        string memory description;
        string memory rarity = rarityToString(calculateRarity(tokenId));
        if (bytes(bug.name).length == 0) {
            name = string.concat(rarity, " ", species.name);
            description = species.description;
        } else {
            name = bug.name;
            description = string.concat(species.name, ": ", species.description);
        }
        string memory metadataJson = string.concat(
            '{',
                '"name": "', name, '",',
                '"species": "', species.name, '",',
                '"description": "', description, '",',
                '"image": "', species.image, '",',
                '"attributes":', _makeBugAttributesJson(bug, rarity, tokenId),
            '}'
        );

        return string.concat(
            "data:application/json;base64,",
            Base64.encode(bytes(metadataJson))
        );
    }

    function getSpeciesData(uint tokenId) public view returns (SpeciesData memory) {
        return speciesDatas[_getSpeciesId(tokenId)];
    }

    function calculateStats(uint tokenId) public view returns(Stats memory) {
        Rarity rarity = calculateRarity(tokenId);
        
        uint additionalPoints;
        if (rarity == Rarity.COMMON) {
            additionalPoints = 5;
        } else if (rarity == Rarity.UNCOMMON) {
            additionalPoints = 8;
        } else if (rarity == Rarity.RARE) {
            additionalPoints = 11;
        } else if (rarity == Rarity.EPIC) {
            additionalPoints = 14;
        } else if (rarity == Rarity.LEGENDARY) {
            additionalPoints = 17;
        }

        bytes32 random = keccak256(abi.encodePacked(tokenId, "ATTRIBUTES"));
        uint8[] memory statsIncrease = new uint8[](ATTRIBUTES_COUNT);
        for (uint i = 0; i < additionalPoints; i++) {
            uint attribute = uint(random) % ATTRIBUTES_COUNT;
            statsIncrease[attribute]++;
            random = keccak256(abi.encodePacked(random));
        }

        Stats memory baseStats = speciesDatas[_getSpeciesId(tokenId)].baseStats;
        return Stats(
            baseStats.intelligence + statsIncrease[0],
            baseStats.nimbleness + statsIncrease[1],
            baseStats.strength + statsIncrease[2],
            baseStats.endurance + statsIncrease[3],
            baseStats.charisma + statsIncrease[4],
            baseStats.talent + statsIncrease[5]
        );
    }

    function tokenURIsByOwnerAndIndexRange(
        address owner,
        uint fromIndex,
        uint toIndex
    ) public view returns(string[] memory) {
        string[] memory uris = new string[](toIndex - fromIndex + 1);
        for (uint i = fromIndex; i <= toIndex; i++) {
            uint tokenId = tokenOfOwnerByIndex(owner, i);
            uris[i - fromIndex] = tokenURI(tokenId);
        }

        return uris;
    }

    function calculateRarity(uint tokenId) public pure returns (Rarity) {
        uint rarityPercentage = uint(keccak256(abi.encodePacked(tokenId, "RARITY"))) % PRECISION;

        if (isPremium(tokenId)){
            if (rarityPercentage < 5000) return Rarity.UNCOMMON;
            if (rarityPercentage < 9000) return Rarity.RARE;
            if (rarityPercentage < 9700) return Rarity.EPIC;
            return Rarity.LEGENDARY;
        } else {
            if (rarityPercentage < 6000) return Rarity.COMMON;
            if (rarityPercentage < 8500) return Rarity.UNCOMMON;
            if (rarityPercentage < 9500) return Rarity.RARE;
            if (rarityPercentage < 9850) return Rarity.EPIC;
            return Rarity.LEGENDARY;
        }
    }

    function rarityToString(Rarity rarity) public pure returns (string memory) {
        if (rarity == Rarity.COMMON) return "Common";
        if (rarity == Rarity.UNCOMMON) return "Uncommon";
        if (rarity == Rarity.RARE) return "Rare";
        if (rarity == Rarity.EPIC) return "Epic";
        if (rarity == Rarity.LEGENDARY) return "Legendary";
        revert("TheBugs: invalid rarity");
    }

    function isPremium(uint tokenId) public pure returns (bool) {
        return tokenId >> 255 == 1;
    }

    function _initBugData(uint tokenId, string memory name) private {
        Stats memory stats = calculateStats(tokenId);
        bugDatas[tokenId] = BugData(name, stats);
    }

    function _getSpeciesId(uint tokenId) private pure returns (uint) {
        return uint(keccak256(abi.encodePacked(tokenId, "SPECIES"))) % SPECIES_COUNT;
    }

    function _makeBoolAttributeJson(string memory name, bool value) private pure returns (string memory) {
        string memory valueString;
        if (value) {
            valueString = "true";
        } else {
            valueString = "false";
        }

        return string.concat(
            '{',
                '"trait_type": "', name, '",', 
                '"value": ', valueString,
            '}'
        );
    }

    function _makeStringAttributeJson(string memory name, string memory value) private pure returns (string memory) {
        return string.concat(
            '{',
                '"trait_type": "', name, '",', 
                '"value": "', value, '"',
            '}'
        );
    }

    function _makeUintAttributeJson(string memory name, uint value) private pure returns (string memory) {
        return string.concat(
            '{',
                '"trait_type": "', name, '",', 
                '"value": ', value.toString(),
            '}'
        );
    }

    function _makeNumberTypeAttributeJson(string memory name, uint value) private pure returns (string memory) {
        return string.concat(
            '{',
                '"display_type": "number",',
                '"trait_type": "', name, '",', 
                '"value": ', value.toString(),
            '}'
        );
    }

    function _makeBugStatsAttributesJson(Stats memory stats) private pure returns (string memory) {
        return string.concat(
            _makeUintAttributeJson("Intelligence", stats.intelligence),",",
            _makeUintAttributeJson("Nimbleness", stats.nimbleness),",",
            _makeUintAttributeJson("Strength", stats.strength),",",
            _makeUintAttributeJson("Endurance", stats.endurance),",",
            _makeUintAttributeJson("Charisma", stats.charisma),",",
            _makeUintAttributeJson("Talent", stats.talent)
        );
    }

    function _makeBugAttributesJson(BugData storage bug, string memory rarity, uint tokenId) private view returns (string memory) {
        Stats memory stats;
        if (stats.intelligence == 0) { // if any stat is zero, then the bug is not minted yet, calculate stats to show
            stats = calculateStats(tokenId);
        } else {
            stats = bug.stats;
        }

        return string.concat(
            '[',
                _makeStringAttributeJson("Rarity", rarity), ",",
                _makeBugStatsAttributesJson(stats),",",
                _makeNumberTypeAttributeJson("Runs", wins[tokenId] + losses[tokenId] + draws[tokenId]),",",
                _makeNumberTypeAttributeJson("Wins", wins[tokenId]),",",
                _makeBoolAttributeJson("Premium", isPremium(tokenId)),
            ']'
        );
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyRole(UPGRADER_ROLE)
        override
    {}

    // The following functions are overrides required by Solidity.
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(AccessControlEnumerableUpgradeable, ERC721EnumerableUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
