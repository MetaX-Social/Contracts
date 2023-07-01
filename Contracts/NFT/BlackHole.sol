// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract BlackHole is ERC721, AccessControl, Ownable, ReentrancyGuard {

/** Roles **/
    bytes32 public constant Admin = keccak256("Admin");

    bytes32 public constant Claimer = keccak256("Claimer");

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    constructor (
        string[] memory initialTypes
    ) ERC721("BalckHole", "BlackHole") {
        communityTypes = initialTypes;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

/** Community Types **/
    string[] public communityTypes;

    function updateType(uint256 batch, string memory _communityTypes) public onlyRole(Admin) {
        if (batch < communityTypes.length) {
            communityTypes[batch] = _communityTypes;
        } else {
            communityTypes.push(_communityTypes);
        }
    }

/** Metadata **/
    string[] public baseURI;

    function setBaseURI(uint256 batch, string memory newBaseURI) public onlyRole(Admin) nonReentrant {
        if (batch < baseURI.length) {
            baseURI[batch] = newBaseURI;
        } else {
            baseURI.push(newBaseURI);
        }
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "BlackHole: Token not exist.");
        uint256 type_ = Community[_tokenId]._type;
        return bytes(baseURI[type_]).length > 0 ? string(abi.encodePacked(baseURI[type_], Strings.toString(_tokenId), ".json")) : "";
    }

/** Community Deploy **/
    struct _community {
        uint256 _type;
        string[] communityId; /* 0=>Discord | 1=>Twitter | Continues... */
        uint256 POSW;
        uint256 level;
        uint256 birthday;
    }

    mapping (uint256 => _community) public Community;

    function updateTypeByCommunity(uint256 _tokenId, uint256 type_) public onlyRole(Admin) {
        Community[_tokenId]._type = type_;
    }

    function Deploy(uint256 _tokenId, uint256 batch, string calldata _communityId) public onlyRole(Admin) {
        if (batch < Community[_tokenId].communityId.length) {
            Community[_tokenId].communityId[batch] = _communityId;
        } else {
            Community[_tokenId].communityId.push(_communityId);
        }
    }

/** Community Info **/
    function getCommunityId(uint256 _tokenId, uint256 batch) external view returns (string memory) {
        return Community[_tokenId].communityId[batch];
    }

    function getCommunityType(uint256 _tokenId) external view returns (string memory) {
        uint256 _type = Community[_tokenId]._type;
        return communityTypes[_type];
    }

    function getCommunityBirth(uint256 _tokenId) external view returns (uint256) {
        return Community[_tokenId].birthday;
    }

/** POSW of Builders **/
    function _addPOSW(uint256 _tokenId, uint256 _POSW) external onlyRole(Claimer) nonReentrant {
        require(_exists(_tokenId), "BlackHole: Token not exist.");
        Community[_tokenId].POSW += _POSW;
    }

    function getPOSW(uint256 _tokenId) external view returns (uint256) {
        return Community[_tokenId].POSW;
    }

    function getLevel(uint256 _tokenId) external view returns (uint256) {
        return Community[_tokenId].level;
    }

    function levelUp(uint256 _tokenId) external onlyRole(Claimer) {
        require(Community[_tokenId].level < 9, "BlackHole: You have reached the highest level.");
        Community[_tokenId].level++;
    }

/** Whitelist **/
    bytes32 public merkleRoot;

    function setWhitelist(bytes32 _merkleRoot) public onlyRole(Admin) nonReentrant {
        merkleRoot = _merkleRoot;
    }

    function verify(address sender, uint256 _airdrop, bytes32[] calldata merkleProof) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(sender, _airdrop));
        return MerkleProof.verify(merkleProof, merkleRoot, leaf);
    }

/** Mint **/
    uint256 private tokenId;

    function numberMinted() public view returns (uint256) {
        return tokenId;
    }

    function totalSupply() external view returns (uint256) {
        return tokenId;
    }

    function Price() public view returns (uint256 price) {
        if (numberMinted() >= 100) {
            price = 300 + (numberMinted() - 100) * 10;
        } else {
            price = 0;
        }
    }

    mapping (address => uint256[]) public wallet_token;

    function getAllTokens(address owner) public view returns (uint256[] memory) {
        return wallet_token[owner];
    }

    function Mint(address owner, uint256 _airdrop, bytes32[] calldata merkleProof) public payable {
        require(tx.origin == msg.sender, "BlackHole: Contract not allowed.");
        require(_airdrop == 0 || _airdrop == 1, "BlackHole: Incorrect airdrop input.");
        require(verify(owner, _airdrop, merkleProof), "BlackHole: You are not in the whitelist.");
        if (_airdrop != 1) {
            require(msg.value >= Price() * 1 ether, "BlackHole: Not enough payment.");
        }
        tokenId++;
        _safeMint(owner, tokenId);

        Community[tokenId].birthday = block.timestamp;

        wallet_token[owner].push(tokenId);

        emit mintRecord(owner, tokenId, block.timestamp);
    }

    event mintRecord(address indexed owner, uint256 indexed tokenId, uint256 indexed time);

/** Soul Bound Token **/
    function _beforeTokenTransfer(address from, address to, uint256 firstTokenId, uint256 batchSize) internal virtual override {
        require(from == address(0) || to == address(0), "BlackHole: SBT can't be transfered.");
        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);
    }

/** Undeploy By Burning **/
    function Burn(uint256 _tokenId) public {
        require(ownerOf(_tokenId) == msg.sender, "BlackHole: You are not the owner of this SBT.");
        _burn(_tokenId);
        uint256[] storage token = wallet_token[msg.sender];
        for (uint256 i=0; i<token.length; i++) {
            if(token[i] == tokenId) {
                token[i] = token[token.length - 1];
                token.pop();
                break;
            }
        }
    }

/** Withdraw **/
    function Withdraw(address recipient) public payable onlyOwner {
        payable(recipient).transfer(address(this).balance);
    }
}