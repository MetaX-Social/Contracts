// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "../Interface/IMetaX.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract BuilderIncentives is Ownable, AccessControl {

/** Roles **/
    bytes32 public constant Admin = keccak256("Admin");

    constructor(
        uint256 _T0,
        uint256 _Today
    ) {
        T0 = _T0;
        Today = _Today;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

/** MetaX Smart Contracts **/
    /* $MetaX */
    address public MetaX_Addr;

    IERC20 public MX;

    function setMetaX(address _MetaX_Addr) public onlyOwner {
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

    /* PlanetBadges */
    address public PlanetBadges_Addr;

    IERC721 public PB;

    function setPlanetBadges(address _PlanetBadges_Addr) public onlyOwner {
        PlanetBadges_Addr = _PlanetBadges_Addr;
        PB = IERC721(_PlanetBadges_Addr);
    }

    /* Excess Claimable Builder */
    address public ExcessClaimableBuilder;

    IMetaX public ECB;

    function setExcessClaimableBuilder(address _ExcessClaimableBuilder) public onlyOwner {
        ExcessClaimableBuilder = _ExcessClaimableBuilder;
        ECB = IMetaX(_ExcessClaimableBuilder);
    }

/** Daily Quota **/
    uint256 public T0;

    uint256 public dailyQuota = 684931.5068493151 ether; /* Halve every 2 years */

    function Halve() public onlyRole(Admin) {
        require(block.timestamp >= T0 + 730 days, "SocialMining: Halving every 2 years.");
        dailyQuota /= 2;
        for (uint256 i=0; i<Rate.length; i++) {
            Rate[i] /= 2;
            Limit[i] /= 2;
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

/** Builder Incentives Ability **/
    uint256[] public Rate = [ 
    /* Rate * 10 ** 14 */
          100, /* Lv.1  */
          200, /* Lv.2  */
          300, /* Lv.3  */
          400, /* Lv.4  */
          500, /* Lv.5  */
          650, /* Lv.6  */
          800, /* Lv.7  */
         1000, /* Lv.8  */
         1200, /* Lv.9  */
         1500, /* Lv.10 */
         1750, /* Lv.11 */
         1860, /* Lv.12 */
         2000  /* Lv.13 */
    ];

    uint256[] public Limit = [
    /* Limit * 10 ** 18 */
         3000, /* Lv.1  */
         4380, /* Lv.2  */
         5000, /* Lv.3  */
         6800, /* Lv.4  */
         8000, /* Lv.5  */
        10000, /* Lv.6  */
        13800, /* Lv.7  */
        18000, /* Lv.8  */
        25000, /* Lv.9  */
        30000, /* Lv.10 */
        35000, /* Lv.11 */
        40000, /* Lv.12 */
        50000  /* Lv.13 */
    ];

/** Builder $MetaX Claiming **/
    /* POSW Verification for Builder */
    bytes32 public merkleRoot;

    function setRoot(bytes32 _merkleRoot) public onlyRole(Admin) {
        merkleRoot = _merkleRoot;
    }

    function verify(uint256 _POSW, uint256 tokenId_BH, uint256 _PG, bytes32[] calldata merkleProof) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, _POSW, tokenId_BH, _PG));
        return MerkleProof.verify(merkleProof, merkleRoot, leaf);
    }

    mapping (uint256 => uint256) public recentClaimed; /* SBT tokenId => recent claimed time */

    /* Claim $MetaX for Builder */
    function Algorithm(uint256 _POSW, uint256 _tokenId_BH, uint256 _PG) public view returns (uint256, uint256) {
        uint256 amount;
        uint256 _level  = BH.getLevel(_tokenId_BH);
        if (_PG == 1) {
            _level += 3;
        }
        uint256 _rate   = Rate[_level];
        uint256 _limit  = Limit[_level] * 10000;
        if (PB.balanceOf(msg.sender) >= 10) { 
            _rate  = _rate * 110 / 100;
            _limit = _limit * 110 / 100;
        }
        uint256 _decimals = 10**14;
        uint256 todayClaimable = _POSW * _rate + ECB._getExcess(_tokenId_BH)/_decimals;
        uint256 todayExcess;
        if (todayClaimable > _limit) {
            amount = _limit;
            todayExcess = todayClaimable - _limit;
        } else {
            amount = todayClaimable;
        }
        if (todayClaimed/_decimals + amount > dailyQuota/_decimals) {
            todayExcess += (todayClaimed/_decimals + amount - dailyQuota/_decimals);
            amount = dailyQuota/_decimals - todayClaimed/_decimals;
        }
        amount *= _decimals;
        todayExcess *= _decimals;
        return(amount, todayExcess);
    }

    function Amount(uint256 _POSW, uint256 _tokenId_BH, uint256 _PG) public view returns (uint256) {
        (uint256 amount, ) = BuilderIncentives.Algorithm(_POSW, _tokenId_BH, _PG);
        return amount;
    }

    function Excess(uint256 _POSW, uint256 _tokenId_BH, uint256 _PG) public view returns (uint256) {
        (, uint256 todayExcess) = BuilderIncentives.Algorithm(_POSW, _tokenId_BH, _PG);
        return todayExcess;
    }

    function Claim_Builder (uint256 _POSW, uint256 _tokenId_BH, uint256 _PG, bytes32[] calldata merkleProof) public {
        require(IERC721(BlackHole_Addr).ownerOf(_tokenId_BH) == msg.sender, "BuilderIncentives: You are not the owner of this SBT.");
        require(verify(_POSW, _tokenId_BH, _PG, merkleProof), "BuilderIncentives: Incorrect POSW.");
        require(block.timestamp <= Today + 1 days, "BuilderIncentives: Today's claiming process has not started.");
        require(recentClaimed[_tokenId_BH] < Today, "BuilderIncentives: You can claim only once per day.");
        require(todayClaimed < dailyQuota, "BuilderIncentives: Exceed today's limit.");
        uint256 amount = Amount(_POSW, _tokenId_BH, _PG);
        uint256 todayExcess = Excess(_POSW, _tokenId_BH, _PG);
        MX.transfer(msg.sender, amount);
        todayClaimed += amount;
        ECB._setExcess(_tokenId_BH, todayExcess);
        recentClaimed[_tokenId_BH] = block.timestamp;
        BH._addPOSW(_tokenId_BH, _POSW);
        emit builderClaimRecord(msg.sender, _tokenId_BH, _POSW, amount, todayExcess, block.timestamp);
    }

    event builderClaimRecord(address indexed builder, uint256 indexed _tokenId, uint256 _POSW, uint256 indexed $MetaX, uint256 Excess, uint256 _time);
}