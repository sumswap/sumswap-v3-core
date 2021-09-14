// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity =0.7.6;

import '../mainContracts/Summa.sol';

contract SummaTest is Summa{
  constructor()  Summa(3.2 * 10 ** 18) payable{
      
  }
}
