// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "../Interface/IMetaX.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract LevelUp is AccessControl, Ownable {

/** Roles **/
    bytes32 public constant Admin = keccak256("Admin");

    constructor(
        uint256 _T0
    ) {
        T0 = _T0;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

/** Smart Contracts Preset **/
    /* $MetaX */
    address public MetaX_Addr;

    IERC20 public MX;

    function setMetaX(address _MetaX_Addr) public onlyOwner {
        MetaX_Addr = _MetaX_Addr;
        MX = IERC20(_MetaX_Addr);
    }

    /* Vault */
    address public Vault;

    function setVault(address _Vault) public onlyOwner {
        Vault = _Vault;
    }

    /* XPower of PlanetMan */
    address public PlanetMan_XPower;

    IMetaX public PM;

    function setPlanetMan(address _PlanetMan_XPower) public onlyOwner {
        PlanetMan_XPower = _PlanetMan_XPower;
        PM = IMetaX(_PlanetMan_XPower);
    }

    /* BlackHole SBT */
    address public BlackHole_Addr;

    IMetaX public BH;

    function setBlackHole(address _BlackHole_Addr) public onlyOwner {
        BlackHole_Addr = _BlackHole_Addr;
        BH = IMetaX(_BlackHole_Addr);
    }

    /* Excess Claimable User */
    address public ExcessClaimableUser;

    IMetaX public ECU;

    function setExcessClaimableUser(address _ExcessClaimableUser) public onlyOwner {
        ExcessClaimableUser = _ExcessClaimableUser;
        ECU = IMetaX(_ExcessClaimableUser);
    }

    /* Excess Claimable Builder */
    address public ExcessClaimableBuilder;

    IMetaX public ECB;

    function setExcessClaimableBuilder(address _ExcessClaimableBuilder) public onlyOwner {
        ExcessClaimableBuilder = _ExcessClaimableBuilder;
        ECB = IMetaX(_ExcessClaimableBuilder);
    }

/** Price in $MetaX * 10**18 **/
    uint256[] public consume = [10000, 25000, 45000, 65000, 100000, 200000, 300000, 400000, 500000];

    uint256 public T0;

    function Halve() public onlyOwner {
        require(block.timestamp >= T0 + 730 days, "Level Up: Halving every 2 years.");
        for (uint256 i=0; i<consume.length; i++) {
            consume[i] /= 2;
        }
        T0 += 730 days;
    }

/** Level Up PlanetMan **/

    /* PlanetMan Verification */
    bytes32 public merkleRoot;

    function setRoot(bytes32 _merkleRoot) public onlyRole(Admin) {
        merkleRoot = _merkleRoot;
    }

    function verify(uint256 _tokenId, bytes32[] calldata merkleProof) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, _tokenId));
        return MerkleProof.verify(merkleProof, merkleRoot, leaf);
    }

    /* Level up requirement in POSW for PlanetMan */
    uint256[] public level_PM = [3000, 10000, 20000, 30000, 50000, 80000, 150000, 300000, 500000];

    function levelUp_PM(uint256 _tokenId, bytes32[] calldata merkleProof, uint8 v, bytes32 r, bytes32 s) public payable {
        uint256 _level = PM.getLevel(_tokenId);
        uint256 _POSW = PM.getPOSW(_tokenId);
        uint256 _consume = consume[_level] * 1 ether;
        uint256 _excess = ECU.getExcess(msg.sender);
        require(verify(_tokenId, merkleProof), "XPower: You are not the owner of PlanetMan.");
        require(_level < 9, "XPower: You have reached the highest level.");
        require(_POSW >= level_PM[_level], "XPower: You are not qualified for level up.");
        require(MX.balanceOf(msg.sender) + _excess >= _consume, "XPower: You don't have enough $MetaX to finish the level up.");

        if (_excess >= _consume) {
            ECU.consumeExcess(msg.sender, _consume);
        } else {
            uint256 _Consume = _consume - _excess;
            ECU.consumeExcess(msg.sender, _excess);
            IERC20Permit(MetaX_Addr).permit(msg.sender, address(this), _Consume, block.timestamp+86400, v, r, s);
            MX.transferFrom(msg.sender, Vault, _Consume);
        }
        
        PM.levelUp(_tokenId);
    }

/** Level Up BlackHole **/
    /* Level up requirement in POSW of BlackHole */
    uint256[] public level_BH = [300000, 1000000, 2000000, 3000000, 5000000, 8000000, 15000000, 30000000, 50000000];

    function levelUp_BH(uint256 _tokenId, uint8 v, bytes32 r, bytes32 s) public payable {
        uint256 _level = BH.getLevel(_tokenId);
        uint256 _POSW = BH.getPOSW(_tokenId);
        uint256 _consume = consume[_level] * 1 ether;
        require(IERC721(BlackHole_Addr).ownerOf(_tokenId) == msg.sender, "BlackHole: You are not the owner of this NFT.");
        require(_level < 9, "BlackHole: You have reached the highest level.");
        require(_POSW >= level_BH[_level], "BlackHole: You are not qualified for level up.");

        uint256 _excess = ECB._getExcess(_tokenId);
        require(MX.balanceOf(msg.sender) + _excess >= _consume, "BlackHole: You don't have enough $MetaX to finish the level up.");

        if (_excess >= _consume) {
            ECB._consumeExcess(_tokenId, _consume);
        } else {
            uint256 _Consume = _consume - _excess;
            ECB._consumeExcess(_tokenId, _excess);
            IERC20Permit(MetaX_Addr).permit(msg.sender, address(this), _Consume, block.timestamp+86400, v, r, s);
            MX.transferFrom(msg.sender, Vault, _Consume);
        }

        BH.levelUp(_tokenId);
    }
}