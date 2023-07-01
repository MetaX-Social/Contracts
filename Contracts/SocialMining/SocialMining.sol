// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "../Interface/IMetaX.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract SocialMining is AccessControl, Ownable {

/** Roles **/
    bytes32 public constant Admin = keccak256("Admin");

    bytes32 public constant Claimer = keccak256("Claimer");

    constructor(
        uint256 _T0,
        uint256 _Today
    ) {
        T0 = _T0;
        Today = _Today;
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

    /* PlanetBadges */
    address public PlanetBadges_Addr;

    IERC721 public PB;

    function setPlanetBadges(address _PlanetBadges_Addr) public onlyOwner {
        PlanetBadges_Addr = _PlanetBadges_Addr;
        PB = IERC721(_PlanetBadges_Addr);
    }

    /* Excess Claimable User */
    address public ExcessClaimableUser;

    IMetaX public ECU;

    function setExcessClaimableUser(address _ExcessClaimableUser) public onlyOwner {
        ExcessClaimableUser = _ExcessClaimableUser;
        ECU = IMetaX(_ExcessClaimableUser);
    }

    /* Vault */
    address public Vault;

    function setVault(address _Vault) public onlyOwner {
        Vault = _Vault;
    }

/** Daily Quota **/
    uint256 public T0;

    uint256 public dailyQuota = 5479452.054794521 ether; /* Halve every 2 years */

    function Halve() public onlyRole(Admin) {
        require(block.timestamp >= T0 + 730 days, "SocialMining: Halving every 2 years.");
        dailyQuota /= 2;
        for (uint256 i=0; i<Rate.length; i++) {
            for (uint256 j=0; j<Rate[0].length; j++) {
                Rate[i][j] /= 2;
                Limit[i][j] /= 2;
            }
        }
        T0 += 730 days;
    }

    uint256 public Today;

    uint256 public todayClaimed;

    function setToday() public onlyRole(Admin) {
        require(block.timestamp - Today > 1 days, "SocialMining: Still within today.");
        Today += 1 days;
        todayClaimed = 0;
    }

    function _fixToday(uint256 _today, uint256 _todayClaimed) public onlyRole(Admin) {
        Today = _today;
        todayClaimed = _todayClaimed;
    }

/** Social Mining Ability **/
    function Rarity(uint256 _tokenId) public pure returns (uint256 rarity) {
        require(_tokenId <= 10000, "SocialMining: Token not exist.");
        if (0<_tokenId && _tokenId<=50) {
            rarity = 4;
        } else if (50<_tokenId && _tokenId<=500) {
            rarity = 3;
        } else if (500<_tokenId && _tokenId<=2000) {
            rarity = 2;
        } else if (2000<_tokenId && _tokenId<=7000) {
            rarity = 1;
        } else if (7000<_tokenId && _tokenId<=10000) {
            rarity = 0;
        }
    }

    uint256[][] public Rate = [ /* Rate * 10 ** 15 */
        [ 200,  220,  250,  300,  380,  500,  620,  750,  880, 1000, 1150, 1300, 1500],
        [ 300,  380,  500,  680,  880, 1000, 1180, 1350, 1500, 1620, 1780, 1900, 2000],
        [ 800, 1200, 1500, 1720, 1860, 2000, 2380, 2700, 2830, 3000, 3230, 3500, 4000],
        [1600, 1880, 2000, 2300, 2500, 2800, 3200, 3500, 4000, 4300, 4680, 5000, 6000],
        [2500, 2880, 3200, 3600, 4000, 4500, 5200, 5800, 6600, 7500, 8300, 9000, 10000]
    ]; /* Halve every 2 years */

    uint256[][] public Limit = [ /* Limit * 10 ** 19 */
        [ 200,  220,  250,  268,  300,  370,  460,  550,  640,  720,  800,  900, 1000],
        [ 300,  380,  500,  750, 1000, 1320, 1680, 2000, 2400, 2800, 3000, 3350, 3500],
        [ 800, 1000, 1300, 1800, 2200, 2680, 3150, 3500, 3800, 4000, 4400, 4680, 5000],
        [1500, 1800, 2300, 2800, 3500, 4000, 4500, 5000, 5400, 5700, 6000, 6300, 7000],
        [2800, 3100, 3600, 4200, 4780, 5200, 5680, 6200, 7000, 7750, 8200, 9000, 10000]
    ]; /* Halve every 2 years */

/** User $MetaX Claiming **/
    /* POSW Verification for User */
    bytes32 public merkleRoot;

    function setRoot(bytes32 _merkleRoot) public onlyRole(Admin) {
        merkleRoot = _merkleRoot;
    }

    function verify(uint256 _POSW, uint256 _tokenId_PM, uint256 _PG, bytes32[] calldata merkleProof) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, _POSW, _tokenId_PM, _PG));
        return MerkleProof.verify(merkleProof, merkleRoot, leaf);
    }

    mapping (address => uint256) public recentClaimed_Wallet;

    mapping (uint256 => uint256) public recentClaimed_PM;

    /* Claim $MetaX for User */
    function Algorithm(uint256 _POSW, uint256 _tokenId_PM, uint256 _PG) public view returns (uint256, uint256) {
        uint256 amount;
        uint256 _rarity = 2; // Rarity(_tokenId_PM); rarity equals to 3 during final test
        uint256 _level  = PM.getLevel(_tokenId_PM);
        if (_PG == 1) {
            _level += 3;
        }
        uint256 _rate   = Rate[_rarity][_level];
        uint256 _limit  = Limit[_rarity][_level] * 10000;
        if (PB.balanceOf(msg.sender) >= 10) { 
            _rate  = _rate * 110 / 100;
            _limit = _limit * 110 / 100;
        }
        uint256 _decimals = 10**15;
        uint256 todayClaimable = _POSW * _rate + ECU.getExcess(msg.sender)/_decimals;
        uint256 todayExcess;
        if (todayClaimable > _limit) {
            amount = _limit;
            todayExcess = todayClaimable - _limit;
        } else {
            amount = todayClaimable;
        }
        if (todayClaimed/_decimals + amount > dailyQuota/_decimals) {
            todayExcess += (todayClaimed/_decimals + amount - dailyQuota/_decimals);
            amount = (dailyQuota - todayClaimed)/_decimals;
        }
        amount *= _decimals;
        todayExcess *= _decimals;
        return (amount, todayExcess);
    }

    function Amount(uint256 _POSW, uint256 _tokenId_PM, uint256 _PG) public view returns (uint256) {
        (uint256 amount, ) = SocialMining.Algorithm(_POSW, _tokenId_PM, _PG);
        return amount;
    }

    function Excess(uint256 _POSW, uint256 _tokenId_PM, uint256 _PG) public view returns (uint256) {
        (, uint256 todayExcess) = SocialMining.Algorithm(_POSW, _tokenId_PM, _PG);
        return todayExcess;
    }

    function Claim_User (uint256 _POSW, uint256 _tokenId_PM, uint256 _PG, bytes32[] calldata merkleProof) public {
        require(verify(_POSW, _tokenId_PM, _PG, merkleProof), "SocialMining: Fail to verify your Identity or POSW.");
        require(block.timestamp <= Today + 1 days, "SocialMining: Today's claiming process has not started.");
        require(recentClaimed_Wallet[msg.sender] < Today, "SocialMining: Every Wallet can claim only once per day.");
        require(recentClaimed_PM[_tokenId_PM] < Today, "SocialMining: Every PlanetMan can claim only once per day.");
        require(todayClaimed < dailyQuota, "SocialMining: Exceed today's limit.");
        uint256 amount = Amount(_POSW, _tokenId_PM, _PG);
        uint256 todayExcess = Excess(_POSW, _tokenId_PM, _PG);
        MX.transfer(msg.sender, amount);
        todayClaimed += amount;
        ECU.setExcess(msg.sender, todayExcess);
        recentClaimed_Wallet[msg.sender] = block.timestamp;
        recentClaimed_PM[_tokenId_PM] = block.timestamp;
        POSW.addPOSW(msg.sender, _POSW);
        PM._addPOSW(_tokenId_PM, _POSW);
        emit userClaimRecord(msg.sender, _tokenId_PM, _POSW, amount, todayExcess, block.timestamp);
    }

    event userClaimRecord(address indexed user, uint256 _tokenId, uint256 indexed _posw, uint256 indexed $MetaX, uint256 Excess, uint256 _time);

/** Extended - User Social Mining with Derivative Series **/
    bool public extensionOpen;

    function setExtension() public onlyOwner {
        extensionOpen = true;
    }

    uint256 public Shares; /* In Basis Points */

    function setShare(uint256 _Shares) public onlyOwner {
        Shares = _Shares;
    }

    function Claim_Derivatives (uint256 _POSW, uint256 _tokenId_PM, uint256 _PG, uint256 _BlackList, bytes32[] calldata merkleProof) public {
        require(extensionOpen, "SocialMining: Social Mining by Extended Series is not open.");
        require(_BlackList != 1, "SocialMining: You are blacklisted due to suspicious social behaviors.");
        require(verify(_POSW, _tokenId_PM, _PG, merkleProof), "SocialMining: Fail to verify your Identity or POSW.");
        require(block.timestamp <= Today + 1 days, "SocialMining: Today's claiming process has not started.");
        require(recentClaimed_Wallet[msg.sender] < Today, "SocialMining: Every Wallet can claim only once per day.");
        require(recentClaimed_PM[_tokenId_PM] < Today, "SocialMining: Every PlanetMan can claim only once per day.");
        require(todayClaimed < dailyQuota, "SocialMining: Exceed today's limit.");
        uint256 amount = Amount(_POSW, _tokenId_PM, _PG);
        uint256 _share = amount * Shares / 10000;
        uint256 _amount = amount - _share;
        uint256 todayExcess = Excess(_POSW, _tokenId_PM, _PG);
        MX.transfer(msg.sender, _amount);
        MX.transfer(Vault, _share);
        todayClaimed += amount;
        ECU.setExcess(msg.sender, todayExcess);
        recentClaimed_Wallet[msg.sender] = block.timestamp;
        recentClaimed_PM[_tokenId_PM] = block.timestamp;
        POSW.addPOSW(msg.sender, _POSW);
        PM._addPOSW(_tokenId_PM, _POSW);
        emit userClaimRecord_Derivative(msg.sender, _tokenId_PM, _POSW, _amount, _share, todayExcess, block.timestamp);
    }

    event userClaimRecord_Derivative(address indexed user, uint256 _tokenId, uint256 indexed _posw, uint256 indexed $MetaX, uint256 share, uint256 Excess, uint256 _time);
}