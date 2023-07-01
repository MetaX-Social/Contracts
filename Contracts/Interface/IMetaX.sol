// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IMetaX {

/** $MetaX **/
    function Burn(address sender, uint256 amount) external;

/** XPower of PlanetMan **/
    function getLevel(uint256 _tokenId) external view returns (uint256);

    function getPOSW(uint256 _tokenId) external view returns (uint256);

    function levelUp(uint256 _tokenId) external;

/** BlackHole SBT **/
    function totalSupply() external view returns (uint256);

    function _addPOSW(uint256 _tokenId, uint256 _POSW) external;

    function getCommunityId(uint256 _tokenId, uint256 batch) external view returns (string memory);

    function getCommunityType(uint256 _tokenId) external view returns (string memory);

    function getCommunityBirth(uint256 _tokenId) external view returns (uint256);

/** POSW **/
    function addPOSW(address user, uint256 _POSW) external;

    function getPOSW(address user) external view returns (uint256);

    function getPOSW_Free(address user) external view returns (uint256);

    /* POSW Request */
    function getPOSW_Contract(address spender, address user, bytes32[] calldata merkleProof) external payable returns (uint256);

/** Excess Claimable User **/
    function getExcess(address sender) external view returns (uint256);

    function setExcess(address sender, uint256 amount) external;

    function consumeExcess(address sender, uint256 amount) external;

/** Excess Claimable Builder **/
    function _getExcess(uint256 _tokenId) external view returns (uint256);

    function _setExcess(uint256 _tokenId, uint256 amount) external;

    function _consumeExcess(uint256 _tokenId, uint256 amount) external;
}