// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "../Interface/IMetaX.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SocialMiningV2 is AccessControl, Ownable {
    using SafeMath for uint256;

/** Roles **/
    bytes32 public constant Admin = keccak256("Admin");

/** Events **/
    event releaseRecord (uint256 Epoch, uint256 release_SM, uint256 release_BI, uint256 time);
    event merkleRootRecord (uint256 Epoch, bytes32[] merkleRoot, uint256 time);
    event claimRecord (address user, uint256 token, uint256 posw, uint256 time);
    event burnRecord (uint256 epoch, uint256 burnAmount, uint256 time);

/** Initialization **/
    constructor () {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(Admin, msg.sender);
    }

/** Smart Contracts Preset **/
    /* $MetaX */
    address public MetaX = 0xdc1B3F63944e0ff11dbaD513FE4175fc0466cE2E;
    IERC20 public MX = IERC20(MetaX);

    /* SocialMining Vault */
    IMetaX public SMV = IMetaX(0x923708845Bdd7CaCC2754735A4DE584314B12caf);

    /* Builder Incentives Vault */
    IMetaX public BIV = IMetaX(0xFD80fD0Fc8540BA036a8477aB4491402a0e076A0);

    /* POSW */
    IMetaX public POSW = IMetaX(0xAdE8D4f355926805e5cDc8277d9c71AD10324E47);

/** Epoch Release **/
    function Release (uint256[] memory batch, bytes32[] memory _merkleRoot) public onlyRole(Admin) {
        require(block.timestamp > Epoch().add(epoch), "SocialMiningV2: Still within the current epoch.");
        if (Balance() > 0) {
            Burn();
        }
        setRoot(batch, _merkleRoot);
        release();
        POSW.setEpoch();
        emit releaseRecord (Epoch(), maxRelease_SM, maxRelease_BI, block.timestamp);
    }

    function release () public onlyRole(Admin) {
        require(block.timestamp > Epoch().add(epoch), "SocialMiningV2: Still within the current epoch.");
        for (uint256 i=0; i<epochInDays; i++) {
            SMV.Release();
            BIV.Release();
        }
    }

    /** Max Release by Epoch **/
    uint256 public T0 = 1676505600; /* Genesis Epoch @Feb 16th 2023 */
    uint256 public epoch = 7 days;
    uint256 public epochInDays = 7;

    function Epoch() public view returns (uint256) {
        return POSW.getEpoch();
    }

    uint256 public maxRelease_SM = 38356164 ether; /* 40% allocation | halve every 2 years | released in epoch */
    uint256 public maxRelease_BI =  4794517 ether; /*  5% allocation | halve every 2 years | released in epoch */

    function Halve() public onlyOwner {
        require(block.timestamp >= T0.add(730 days), "SocialMiningV2: Please wait till next halve.");
        maxRelease_SM = maxRelease_SM.div(2);
        maxRelease_BI = maxRelease_BI.div(2);
        T0 = T0.add(730 days);
    }

/** $MetaX Claiming **/
    mapping (address => uint256) public recentClaimed;

    function getRecentClaimed (address user) public view returns (uint256) {
        return recentClaimed[user];
    }

    /* Verification */
    mapping (uint256 => bytes32) public merkleRoot;

    function setRoot (uint256[] memory batch, bytes32[] memory _merkleRoot) public onlyRole(Admin) {
        for (uint256 i=0; i<batch.length; i++) {
            merkleRoot[batch[i]] = _merkleRoot[i];
        }
        emit merkleRootRecord (Epoch(), _merkleRoot, block.timestamp);
    }

    function verify (uint256 batch, uint256 token, uint256 posw, bytes32[] calldata merkleProof) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, token, posw));
        return MerkleProof.verify(merkleProof, merkleRoot[batch], leaf);
    }

    /* Claim */
    function Claim (uint256 batch, uint256 token, uint256 posw, bytes32[] calldata merkleProof) public {
        require(verify(batch, token, posw, merkleProof), "SocialMiningV2: Incorrect POSW & tokens inputs.");
        require(block.timestamp < Epoch().add(epoch), "SocialMiningV2: Claiming process has not started.");
        require(recentClaimed[msg.sender] < Epoch(), "SocialMiningV2: You have claimed your $MetaX of last epoch.");
        MX.transfer(msg.sender, token);
        POSW.addPOSW(msg.sender, posw);
        recentClaimed[msg.sender] = block.timestamp;
        emit claimRecord (msg.sender, token, posw, block.timestamp);
    }

    /* Balance Check */
    function Balance () public view returns (uint256) {
        return MX.balanceOf(address(this));
    }

    /* Burn Unclaim $MetaX */
    address public immutable burnAddr = 0x000000000000000000000000000000000000dEaD;

    function Burn () public onlyRole(Admin) {
        require(block.timestamp > Epoch().add(epoch), "SocialMiningV2: Still within current epoch.");
        require(Balance() > 0, "SocialMiningV2: No unclaimed $MetaX.");
        MX.transfer(burnAddr, Balance());
        emit burnRecord (Epoch(), Balance(), block.timestamp);
    }
}
