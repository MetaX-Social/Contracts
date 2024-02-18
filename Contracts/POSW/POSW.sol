// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract POSW is ERC20, AccessControl, Ownable {

/** Roles **/
    bytes32 public constant Admin = keccak256("Admin");
    bytes32 public constant Claimer = keccak256("Claimer");

/** Events **/
    event addPOSWRecord (address user, uint256 posw, uint256 time);

/** Initialization **/
    constructor(
        uint256 Epoch0
    ) ERC20 ("ProofOfSocialWork", "POSW") {
        Epoch = Epoch0;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(Admin, msg.sender);
    }

/** Epoch **/
    uint256 public Epoch;

    function setEpoch () public onlyRole(Admin) {
        require(block.timestamp >= Epoch + 7 days, "POSW: Still within current epoch.");
        Epoch += 7 days;
    }

    function getEpoch () public view returns (uint256) {
        return Epoch;
    }

/** Proof of Social Work **/
    /* POSW */
    function addPOSW (address user, uint256 posw) public onlyRole(Claimer) {
        _mint(user, posw);
        emit addPOSWRecord (user, posw, block.timestamp);
    }

    function getPOSW (address user) public view returns (uint256) {
        return balanceOf(user);
    }

    /* Soul-Bound On-Chain Identity */
    function _transfer (address from, address to, uint256 value) internal override {
        require(from == address(0), "POSW: POSW is your on-chain identity & can't be transferred.");
        super._transfer(from, to, value);
    }
}
