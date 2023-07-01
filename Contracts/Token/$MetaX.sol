// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../Interface/IMetaX.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

contract $MetaX is ERC20, ERC20Permit, Ownable, AccessControl, ReentrancyGuard {

/** Roles **/
    bytes32 public constant Admin = keccak256("Admin");

    bytes32 public constant Burner = keccak256("Burner");

    constructor() ERC20("MetaX", "MetaX") ERC20Permit("MetaX") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

/** Token Allocation **/

    uint256 public immutable Max = 20000000000 ether;

    address[] public Vaults = [
        0x5536d1ACd0aF249e087a582db479Ba768F74995D, /* Social Mining 40% */
        0x42B3B01Af349CC744971EaF3FA781D2C8eA8bf5C, /* Builder Incentives 5% */
        0x0000000000000000000000000000000000000000, /* Marketing Expense 10% */
        0x0000000000000000000000000000000000000000, /* Treasure 10% */
        0x0000000000000000000000000000000000000000, /* Team Reserved 15% */
        0x0000000000000000000000000000000000000000, /* Advisors 5% */
        0x0000000000000000000000000000000000000000  /* Investors 15% */
    ];

    function setVaults(uint256 batch, address _Vault) public onlyOwner {
        Vaults[batch] = _Vault;
    }

    uint256[] public Allocation = [
        8000000000, /* Social Mining 40% */
        1000000000, /* Builder Incentives 5% */
        2000000000, /* Marketing Expense 10% */
        2000000000, /* Treasure 10% */
        3000000000, /* Team Reserved 15% */
        1000000000, /* Advisors 5% */
        3000000000  /* Investors 15% */
    ];

    mapping (uint256 => bool) public alreadyMinted;

    function Mint(uint256 batch) public onlyOwner {
        require(!alreadyMinted[batch], "$MetaX: Max 20 Billion.");
        _mint(Vaults[batch], Allocation[batch] * 1 ether);
        alreadyMinted[batch] = true;
    }

/** BlackHole SBT **/
    address public BlackHole_Addr;

    IMetaX public BH;

    function setBlackHole(address _BlackHole_Addr) public onlyOwner {
        require(!BlackHole_Freeze, "$MetaX: BlackHole is frozen.");
        BlackHole_Addr = _BlackHole_Addr;
        BH = IMetaX(_BlackHole_Addr);
    }

    bool public BlackHole_Freeze;

    function Freeze() public onlyOwner {
        BlackHole_Freeze = true;
    }

/** Liquidity Release **/
    function Liquidity() public view returns (bool) {
        if (BH.totalSupply() >= 100) {
            return true;
        } else {
            return false;
        }
    }

    function checkVaults(address from) internal view returns (bool) {
        bool withinVaults;
        for (uint256 i=0; i<Vaults.length; i++) {
            if (Vaults[i] == from) {
                withinVaults = true;
                break;
            } else {
                withinVaults = false;
            }
        }
        return withinVaults;
    }

    function checkConsumptions(address to) internal view returns (bool) {
        bool withinConsumptions;
        for (uint256 i=0; i<Consumptions.length; i++) {
            if (Consumptions[i] == to) {
                withinConsumptions = true;
                break;
            } else {
                withinConsumptions = false;
            }
        }
        return withinConsumptions;
    }

    function _transfer(address from, address to, uint256 amount) internal override {
        if (from != address(0) && to != address(0)) {
            if (!checkVaults(from) && !checkConsumptions(to)) {
                require(Liquidity(), "$MetaX: Liquidity locked until 100 communities deployment.");
            }
        }
        super._transfer(from, to, amount);
    }

/** Burn **/
    address[] public Consumptions = [
        0xC1f4862c56F76DdbA8D40438a58D678FF8736747, /* Vault */
        0x0000000000000000000000000000000000000000,
        0x0000000000000000000000000000000000000000
    ];

    function updateConsumptions(uint256 batch, address _Consumptions) public onlyRole(Admin) {
        if (batch < Consumptions.length) {
            Consumptions[batch] = _Consumptions;
        } else {
            Consumptions.push(_Consumptions);
        }
    }

    function Burn(address sender, uint256 amount) external onlyRole(Burner) {
        require(balanceOf(sender) >= amount, "$MetaX: You don't have enough amount of $MetaX.");
        _burn(sender, amount);
    }
}