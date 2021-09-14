// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity =0.7.6;

import '../mainContracts/SummaPri.sol';

contract SummaPriTest is SummaPri{
  constructor(address summaAddr)  SummaPri(summaAddr) payable{
    
  }
}
