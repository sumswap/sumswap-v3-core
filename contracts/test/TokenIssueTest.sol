// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity =0.7.6;

import '../mainContracts/TokenIssue.sol';

contract TokenIssueTest is TokenIssue{
  constructor(address _summa,address _summaPri)  TokenIssue(_summa,_summaPri) payable{
      
  }
}
