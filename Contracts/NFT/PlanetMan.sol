// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import { DefaultOperatorFilterer } from "./Opensea/DefaultOperatorFilterer.sol";

contract PlanetMan is ERC721, Ownable, ERC2981, DefaultOperatorFilterer {

    constructor(
        string memory _baseURI,
        address receiver,
        uint96 feeNumerator
    ) ERC721("PlanetMan", "PlanetMan") {
        tokenIdByRarity[0] = 7000;
        tokenIdByRarity[1] = 2000;
        tokenIdByRarity[2] = 500;
        tokenIdByRarity[3] = 50;
        tokenIdByRarity[4] = 0;
        baseURI = _baseURI;
        _setDefaultRoyalty(receiver, feeNumerator);
    }

/** Metadata of PlanetMan **/
    string public baseURI;

    function setBaseURI(string memory newBaseURI) public onlyOwner {
        baseURI = newBaseURI;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "PlanetMan: Token not exist.");
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, Strings.toString(tokenId), ".json")) : "";
    }

/** Free Mint Whitelist **/
    bytes32 public merkleRoot;

    function setWhitelist(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function verify(address sender, uint256 _rarity, bytes32[] calldata merkleProof) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(sender, _rarity));
        return MerkleProof.verify(merkleProof, merkleRoot, leaf);
    }

/** Mint **/
    /* Status */
    bool public Open;

    function setOpen(bool _Open) public onlyOwner {
        Open = _Open;
    }

    /* Quantity */
    uint256 public totalSupply;

    uint256 public immutable Max = 10000;

    uint256[] public maxRarity  = [3000, 5000, 1500, 450, 50];

    uint256[] public maxPublic  = [3000, 4850, 1420, 435, 45];

    uint256[] public maxAirdrop = [   0,  150,   50,   0,  0];

    uint256[] public maxReserve = [   0,    0,   30,  15,  5];

    mapping (uint256 => uint256) public numberMinted;    /* Quantity minted for every rarity */

    mapping (uint256 => uint256) public numberAirdroped; /* Quantity airdroped for every rarity */

    mapping (uint256 => uint256) public numberReserved;  /* Quantity reserved for every rarity */

    /* Price */
    uint256[] public Price = [0 ether, 0.02 ether, 0.08 ether, 0.2 ether, 0.5 ether];

    /* Rarity */
    mapping (uint256 => uint256) public tokenIdByRarity; /* Track minting progress of different rarity */

    mapping (uint256 => uint256) private rarity; /* Mapping tokenId to Rarity */

    function Rarity(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "PlanetMan: Token not exist.");
        return rarity[tokenId];
    }

    /* Mint Limit */
    mapping (address => mapping(uint256 => bool)) public alreadyMinted;

    event mintRecord(address indexed owner, uint256 indexed tokenId, uint256 indexed time);

    /* Public Mint */
    function Mint(address owner, uint256 _rarity, bytes32[] calldata merkleProof) public payable {
        require(Open, "PlanetMan: Mint is closed.");
        require(tx.origin == msg.sender, "PlanetMan: Contracts are not allowed.");
        require(_rarity < 5, "PlanetMan: Incorrect rarity inputs.");
        require(!alreadyMinted[owner][_rarity], "PlanetMan: Limit 1 per rarity.");
        require(totalSupply < Max, "PlanetMan: Exceed the max supply.");
        require(numberMinted[_rarity] < maxPublic[_rarity], "PlanetMan: Exceed the public mint limit of that rarity.");
        uint256 _Price = Price[_rarity];
        if (!verify(owner, _rarity, merkleProof)) {
            require(msg.value >= _Price, "PlanetMan: Not enough payment.");
        }
        tokenIdByRarity[_rarity] ++;
        uint256 tokenId = tokenIdByRarity[_rarity];

        _safeMint(owner, tokenId);

        numberMinted[_rarity] ++;
        totalSupply ++;
        rarity[tokenId] = _rarity;
        alreadyMinted[owner][_rarity] = true;

        emit mintRecord(owner, tokenId, block.timestamp);
    }

    /* Airdrop Mint */
    function Airdrop(address owner, uint256 _rarity) public onlyOwner {
        require(_rarity < 5, "PlanetMan: Incorrect rarity inputs.");
        require(totalSupply < Max, "PlanetMan: Exceed the max supply.");
        require(numberAirdroped[_rarity] < maxAirdrop[_rarity], "PlanetMan: Exceed the airdrop limit of that rarity.");
        tokenIdByRarity[_rarity] ++;
        uint256 tokenId = tokenIdByRarity[_rarity];

        _safeMint(owner, tokenId);

        numberAirdroped[_rarity] ++;
        totalSupply ++;
        rarity[tokenId] = _rarity;

        emit mintRecord(owner, tokenId, block.timestamp);
    }

    /* Reserve Mint */
    function Reserve(address _reserve, uint256 _rarity) public onlyOwner {
        require(_rarity < 5, "PlanetMan: Incorrect rarity inputs.");
        require(numberReserved[_rarity] < maxReserve[_rarity], "PlanetMan: Exceed the reserve limit of that rarity.");
        require(totalSupply < Max, "PlanetMan: Exceed the max supply.");
        tokenIdByRarity[_rarity] ++;
        uint256 tokenId = tokenIdByRarity[_rarity];

        _safeMint(_reserve, tokenId);
        
        numberReserved[_rarity] ++;
        totalSupply ++;
        rarity[tokenId] = _rarity;

        emit mintRecord(_reserve, tokenId, block.timestamp);
    }

/** Binding Tokens With Wallet Address **/
    mapping (address => uint256[]) public wallet_token;

    function getAllTokens(address owner) public view returns (uint256[] memory) {
        return wallet_token[owner];
    }

    function addToken(address user, uint256 tokenId) internal {
        wallet_token[user].push(tokenId);
    }

    function removeToken(address user, uint256 tokenId) internal {
        uint256[] storage token = wallet_token[user];
        for (uint256 i=0; i<token.length; i++) {
            if(token[i] == tokenId) {
                token[i] = token[token.length - 1];
                token.pop();
                break;
            }
        }
    }

    function _beforeTokenTransfer(address from, address to, uint256 firstTokenId, uint256 batchSize) internal virtual override {
        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);
        for (uint256 i=0; i<batchSize; i++) {
            uint256 tokenId = firstTokenId + i;
            if (from != address(0)) {
                removeToken(from, tokenId);
            }
            if (to != address(0)) {
                addToken(to, tokenId);
            }
        }
    }

/** Royalty **/
    function setRoyaltyInfo(address receiver, uint96 feeNumerator) external onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function setTokenRoyalty(uint256 tokenId, address receiver, uint96 feeNumerator) external onlyOwner {
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
    }

    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

/** Withdraw **/
    function Withdraw(address recipient) public payable onlyOwner {
        payable(recipient).transfer(address(this).balance);
    }
}