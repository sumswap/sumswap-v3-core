// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.7.6;
interface ISummaPri{
     function getRelation(address addr) external view returns (address);
     
     
     function hasRole(bytes32 role, address account) external view returns (bool);
     
    
}