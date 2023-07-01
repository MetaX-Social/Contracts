// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract ExcessClaimableBuilder is AccessControl, Ownable {
    
/** Roles **/
    bytes32 public constant Claimer = keccak256("Claimer");

    bytes32 public constant Consumer = keccak256("Consumer");

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

/** Excess Claimable **/
    mapping (uint256 => uint256) public ExcessClaimable;

    function _getExcess(uint256 _tokenId) external view returns (uint256) {
        return ExcessClaimable[_tokenId];
    }

    function _setExcess(uint256 _tokenId, uint256 amount) external onlyRole(Claimer) {
        ExcessClaimable[_tokenId] = amount;
    }

    function _consumeExcess(uint256 _tokenId, uint256 amount) external onlyRole(Consumer) {
        require(ExcessClaimable[_tokenId] >= amount, "Excess Claimable Builder: Not enough $MetaX claimable balance.");
        ExcessClaimable[_tokenId] -= amount;
    }
}