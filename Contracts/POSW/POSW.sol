// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract ProofOfSocialWork is Ownable, AccessControl, ReentrancyGuard {

/** Roles **/
    bytes32 public constant Admin = keccak256("Admin");

    bytes32 public constant Claimer = keccak256("Claimer");

    bytes32 public constant Requestor = keccak256("Requestor");

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

/** POSW | Proof of Social Work **/
    mapping (address => uint256) private POSW;

    function addPOSW(address user, uint256 _POSW) external onlyRole(Claimer) nonReentrant {
        POSW[user] += _POSW;
    }

    bool public Open;

    function setOpen(bool _Open) public onlyRole(Admin) {
        Open = _Open;
    }

    function getPOSW_Free(address user) external view returns (uint256) {
        require(Open, "POSW: POSW free access are not open.");
        return POSW[user];
    }

    function getPOSW(address user) external view onlyRole(Requestor) returns (uint256) {
        return POSW[user];
    }

    function getPOSWbyYourself() public view returns (uint256) {
        return POSW[msg.sender];
    }
}