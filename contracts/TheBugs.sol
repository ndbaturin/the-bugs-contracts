// SPDX-License-Identifier: MIT
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
    using Strings for uint256;

    struct SpeciesData {
        string name;
        string description;
        string image;
    }

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant DATA_SETTER_ROLE = keccak256("DATA_SETTER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    uint public constant SPECIES_COUNT = 12;

    mapping(uint => SpeciesData) public _speciesDatas;

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

    function safeMint(address to, uint tokenId) external onlyRole(MINTER_ROLE) {
        _safeMint(to, tokenId);
    }

    function setSpeciesData(
        uint speciesID,
        SpeciesData calldata speciesData
    ) external onlyRole(DATA_SETTER_ROLE) {
        require(speciesID < SPECIES_COUNT, "TheBugs: invalid spesies ID");

        _speciesDatas[speciesID] = speciesData;
    }
	
	function tokenURI(uint256 tokenId) public view override returns (string memory) {
        SpeciesData memory speciesData = getSpeciesData(tokenId);
        bytes memory dataURI = abi.encodePacked(
            '{',
                '"name": "Bug #', tokenId.toString(), '",',
                '"species": "', speciesData.name, '",',
                '"description": "', speciesData.description, '",',
                '"image": "', speciesData.image, '"',
            '}'
        );

        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(dataURI)
            )
        );
    }

    function getSpeciesData(uint tokenId) public view returns (SpeciesData memory) {
        return _speciesDatas[getSpeciesId(tokenId)];
    }

    function getSpeciesId(uint tokenId) public pure returns (uint) {
        return tokenId % SPECIES_COUNT;
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
