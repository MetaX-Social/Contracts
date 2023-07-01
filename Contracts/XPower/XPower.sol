// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract XPOWER is Ownable, AccessControl {

/** Roles **/
    bytes32 public constant Admin = keccak256("Admin");

    bytes32 public constant Claimer = keccak256("Claimer");

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

/** XPower of PlanetMan **/
    struct _XPower {
        uint256 level;  /* Lv.1 ~ Lv.13 */
        uint256 POSW;
    }

    mapping (uint256 => _XPower) public XPower; /* tokenId => XPower */

    function getLevel(uint256 _tokenId) external view returns (uint256) {
        return XPower[_tokenId].level;
    }

    function getPOSW(uint256 _tokenId) external view returns (uint256) {
        return XPower[_tokenId].POSW;
    }

    function levelUp(uint256 _tokenId) external onlyRole(Claimer) {
        require(XPower[_tokenId].level < 9, "XPower: You have reached the highest level.");
        XPower[_tokenId].level++;
    }

/** POSW of PlanetMan **/
    function _addPOSW(uint256 _tokenId, uint256 _POSW) external onlyRole(Claimer) {
        XPower[_tokenId].POSW += _POSW;
    }

//No need
    function _addPOSW_Test(uint256 _tokenId, uint256 _posw) external {
        XPower[_tokenId].POSW += _posw;
    }

/** Withdraw **/
    function Withdraw(address recipient) public payable onlyOwner {
        payable(recipient).transfer(address(this).balance);
    }
}