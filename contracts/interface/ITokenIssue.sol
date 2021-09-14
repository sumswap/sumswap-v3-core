// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.7.6;
interface ITokenIssue {
    function transByContract(address to, uint256 amount) external;

    function issueInfo(uint256 monthIndex) external view returns (uint256);

    function startIssueTime() external view returns (uint256);

    function issueInfoLength() external view returns (uint256);

    function TOTAL_AMOUNT() external view returns (uint256);

    function DAY_SECONDS() external view returns (uint256);

    function MONTH_SECONDS() external view returns (uint256);

    function INIT_MINE_SUPPLY() external view returns (uint256);
}