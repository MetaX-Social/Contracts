// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "../Interface/IMetaX.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract EarlyBirdUser is Ownable {

/** Smart Contracts Preset **/
    /* MetaX */
    address public MetaX_Addr;

    IERC20 public MX;

    function setMetaX_Addr(address _MetaX_Addr) public onlyOwner {
        MetaX_Addr = _MetaX_Addr;
        MX = IERC20(_MetaX_Addr);
    }

    /* XPower of PlanetMan */
    address public PlanetMan_XPower;

    IMetaX public PM;

    function setPlanetMan(address _PlanetMan_XPower) public onlyOwner {
        PlanetMan_XPower = _PlanetMan_XPower;
        PM = IMetaX(_PlanetMan_XPower);
    }

    /* POSW */
    address public POSW_Addr;

    IMetaX public POSW;

    function setPOSW(address _POSW_Addr) public onlyOwner {
        POSW_Addr = _POSW_Addr;
        POSW = IMetaX(_POSW_Addr);
    }

    /* Excess Claimable User */
    address public ExcessClaimableUser;

    IMetaX public ECU;

    function setExcessClaimableUser(address _ExcessClaimableUser) public onlyOwner {
        ExcessClaimableUser = _ExcessClaimableUser;
        ECU = IMetaX(_ExcessClaimableUser);
    }

/** Early Bird Reward **/
    /* Verify Early Bird Reward */
    bytes32 public merkleRoot;

    function setRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function verify(
        uint256 _tokenId_PM,
        uint256 _EarlyBirdPOSW,
        uint256 _EarlyBirdTokens,
        uint256 _EarlyBirdExcess,
        bytes32[] calldata merkleProof
    ) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, _tokenId_PM, _EarlyBirdPOSW, _EarlyBirdTokens, _EarlyBirdExcess));
        return MerkleProof.verify(merkleProof, merkleRoot, leaf);
    }

    /* Acquire Early Bird Reward to Claimable/POSW/XPower */
    mapping (address => bool) public alreadyEarlyBird;

    function acquireEarlyBird(
        uint256 _tokenId_PM,
        uint256 _EarlyBirdPOSW,
        uint256 _EarlyBirdTokens,
        uint256 _EarlyBirdExcess,
        bytes32[] calldata merkleProof
    ) public {
        require(!alreadyEarlyBird[msg.sender], "Excess Claimable User: You have acquired your early bird reward.");
        require(verify(_tokenId_PM, _EarlyBirdPOSW, _EarlyBirdTokens, _EarlyBirdExcess, merkleProof), "Excess Claimable User: Incorrect early bird reward.");
        uint256 totalExcess = _EarlyBirdExcess + ECU.getExcess(msg.sender);
        ECU.setExcess(msg.sender, totalExcess);
        IMetaX(POSW_Addr).addPOSW(msg.sender, _EarlyBirdPOSW);
        IMetaX(PlanetMan_XPower)._addPOSW(_tokenId_PM, _EarlyBirdPOSW);
        EarlyBirdToken[msg.sender] = _EarlyBirdToken(_EarlyBirdTokens, 1687313687, 1 weeks, 0, 4, 0);
        alreadyEarlyBird[msg.sender] = true;
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

    mapping (address => _EarlyBirdToken) public EarlyBirdToken;

    function Claim_User() public {
        require(block.timestamp >= EarlyBirdToken[msg.sender].recentClaimed + EarlyBirdToken[msg.sender].intervals, "Early Bird User: Please wait for next release.");
        require(EarlyBirdToken[msg.sender].numberClaimed < EarlyBirdToken[msg.sender].maxClaimed, "Early Bird User: You have claimed all your early bird tokens.");
        require(EarlyBirdToken[msg.sender].tokenClaimed < EarlyBirdToken[msg.sender].tokenMax, "Early Bird User: You have claimed all your early bird tokens.");
        
        uint256 tokens = EarlyBirdToken[msg.sender].tokenMax / EarlyBirdToken[msg.sender].maxClaimed;
        MX.transfer(msg.sender, tokens);
        EarlyBirdToken[msg.sender].tokenClaimed += tokens;
        EarlyBirdToken[msg.sender].recentClaimed += EarlyBirdToken[msg.sender].intervals;
        EarlyBirdToken[msg.sender].numberClaimed++;

        emit EarlyBirdRecord(msg.sender, tokens, block.timestamp);
    }

    event EarlyBirdRecord(address indexed user, uint256 indexed tokens, uint256 indexed time);
}