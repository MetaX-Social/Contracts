// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "../Interface/IMetaX.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract EarlyBirdBuilder is Ownable {

/** Smart Contracts Preset **/
    /* MetaX */
    address public MetaX_Addr;

    IERC20 public MX;

    function setMetaX_Addr(address _MetaX_Addr) public onlyOwner {
        MetaX_Addr = _MetaX_Addr;
        MX = IERC20(_MetaX_Addr);
    }

    /* BlackHole SBT */
    address public BlackHole_Addr;

    IMetaX public BH;

    function setBlackHole(address _BlackHole_Addr) public onlyOwner {
        BlackHole_Addr = _BlackHole_Addr;
        BH = IMetaX(_BlackHole_Addr);
    }

    /* Excess Claimable Builder */
    address public ExcessClaimableBuilder;

    IMetaX public ECB;

    function setExcessClaimableBuilder(address _ExcessClaimableBuilder) public onlyOwner {
        ExcessClaimableBuilder = _ExcessClaimableBuilder;
        ECB = IMetaX(_ExcessClaimableBuilder);
    }

/** Early Bird Reward **/
    /* Verify Early Bird Reward */
    bytes32 public merkleRoot;

    function setRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function verify(
        uint256 _tokenId_BH,
        uint256 _EarlyBirdPOSW,
        uint256 _EarlyBirdTokens,
        uint256 _EarlyBirdExcess,
        bytes32[] calldata merkleProof
    ) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(_tokenId_BH, _EarlyBirdPOSW, _EarlyBirdTokens, _EarlyBirdExcess));
        return MerkleProof.verify(merkleProof, merkleRoot, leaf);
    }

    /* Acquire Early Bird Reward to Claimable/POSW/XPower */
    mapping (uint256 => bool) public alreadyEarlyBird;

    function acquireEarlyBird(
        uint256 _tokenId_BH,
        uint256 _EarlyBirdPOSW,
        uint256 _EarlyBirdTokens,
        uint256 _EarlyBirdExcess,
        bytes32[] calldata merkleProof
    ) public {
        require(!alreadyEarlyBird[_tokenId_BH], "Excess Claimable User: You have acquired your early bird reward.");
        require(verify(_tokenId_BH, _EarlyBirdPOSW, _EarlyBirdTokens, _EarlyBirdExcess, merkleProof), "Excess Claimable User: Incorrect early bird reward.");
        uint256 totalExcess = _EarlyBirdExcess + ECB._getExcess(_tokenId_BH);
        ECB._setExcess(_tokenId_BH, totalExcess);
        BH._addPOSW(_tokenId_BH, _EarlyBirdPOSW);
        EarlyBirdToken[_tokenId_BH] = _EarlyBirdToken(_EarlyBirdTokens, 1687313687, 1 weeks, 0, 4, 0);
        alreadyEarlyBird[_tokenId_BH] = true;
    }

    /* Claim Early Bird $MetaX Reward */
    struct _EarlyBirdToken {
        uint256 tokenMax;
        uint256 tokenClaimed;
        uint256 intervals;
        uint256 recentClaimed;
        uint256 maxClaimed;
        uint256 numberClaimed;
    }

    mapping (uint256 => _EarlyBirdToken) public EarlyBirdToken;

    function Claim_Builder(uint256 _tokenId_BH) public {
        require(IERC721(BlackHole_Addr).ownerOf(_tokenId_BH) == msg.sender, "Early Bird Builder: You are not the owner of this BlackHole SBT.");
        require(block.timestamp >= EarlyBirdToken[_tokenId_BH].recentClaimed + EarlyBirdToken[_tokenId_BH].intervals, "Early Bird User: Please wait for next release.");
        require(EarlyBirdToken[_tokenId_BH].numberClaimed < EarlyBirdToken[_tokenId_BH].maxClaimed, "Early Bird User: You have claimed all your early bird tokens.");
        require(EarlyBirdToken[_tokenId_BH].tokenClaimed < EarlyBirdToken[_tokenId_BH].tokenMax, "Early Bird User: You have claimed all your early bird tokens.");
        
        uint256 tokens = EarlyBirdToken[_tokenId_BH].tokenMax / EarlyBirdToken[_tokenId_BH].maxClaimed;
        MX.transfer(msg.sender, tokens);
        EarlyBirdToken[_tokenId_BH].tokenClaimed += tokens;
        EarlyBirdToken[_tokenId_BH].recentClaimed += EarlyBirdToken[_tokenId_BH].intervals;
        EarlyBirdToken[_tokenId_BH].numberClaimed++;

        emit EarlyBirdRecord(_tokenId_BH, tokens, block.timestamp);
    }

    event EarlyBirdRecord(uint256 indexed _tokenId_BH, uint256 indexed tokens, uint256 indexed time);
}