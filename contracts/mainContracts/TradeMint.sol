// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.7.6;
pragma abicoder v2;

import "../libraries/SafeMath.sol";
import "../libraries/Address.sol";
import "../libraries/trademint/PoolAddress.sol";
import "../interface/IERC20.sol";
import "../interface/ITokenIssue.sol";
import "../libraries/SafeERC20.sol";
import "../interface/trademint/ISummaSwapV3Manager.sol";
import "../interface/trademint/ITradeMint.sol";
import "../libraries/Context.sol";
import "../libraries/Owned.sol";
import "../libraries/FixedPoint128.sol";
import "../libraries/FullMath.sol";
import "../interface/ISummaPri.sol";

contract TradeMint is ITradeMint, Context, Owned {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Address for address;

    ITokenIssue public tokenIssue;

    ISummaSwapV3Manager public iSummaSwapV3Manager;

    uint256 public totalIssueRate = 0.1 * 10000;

    uint256 public settlementBlock;

    mapping(address => bool) public isReward;

    uint256 public totalRewardShare;

    address public factory;
    uint256 public tradeShare;

    bytes32 public constant PUBLIC_ROLE = keccak256("PUBLIC_ROLE");

    uint24 public reduceFee;

    uint24 public superFee;

    struct TickInfo {
        uint256 liquidityVolumeGrowthOutside;
        uint256 liquidityIncentiveGrowthOutside;
        uint256 settlementBlock;
    }

    struct PoolInfo {
        uint256 lastSettlementBlock;
        mapping(int24 => TickInfo) ticks;
        uint256 liquidityVolumeGrowth;
        uint256 liquidityIncentiveGrowth;
        uint256 rewardShare;
        int24 currentTick;
        uint256 unSettlementAmount;
        mapping(uint256 => uint256) blockSettlementVolume;
        address poolAddress;
        mapping(uint256 => uint256) tradeSettlementAmountGrowth;
    }

    struct UserInfo {
        uint256 tradeSettlementedAmount;
        uint256 tradeUnSettlementedAmount;
        uint256 lastTradeBlock;
    }

    struct Position {
        uint256 lastRewardGrowthInside;
        uint256 lastRewardVolumeGrowth;
        uint256 lastRewardSettlementedBlock;
        uint256 tokensOwed;
    }

    struct TradeMintCallbackData {
        bytes path;
        address payer;
        address realplay;
    }

    address[] public poolAddress;

    uint256 public pledgeRate;

    uint256 public minPledge;

    address public summaAddress;

    address public priAddress;

    address public router;

    mapping(uint256 => Position) public _positions;

    mapping(address => mapping(address => UserInfo)) public userInfo;

    mapping(address => PoolInfo) public poolInfoByPoolAddress;

    uint256 public lastWithdrawBlock;

    event Cross(
        int24 _tick,
        int24 _nextTick,
        uint256 liquidityVolumeGrowth,
        uint256 liquidityIncentiveGrowth,
        uint256 tickliquidityVolumeGrowth,
        uint256 tickliquidityIncentiveGrowth
    );

    event Snapshot(
        address tradeAddress,
        int24 tick,
        uint256 liquidityVolumeGrowth,
        uint256 tradeVolume
    );

    event SnapshotMintLiquidity(
        uint256 tokenId,
        address poolAddress,
        int24 _tickLower,
        int24 _tickUpper
    );
    
    event SnapshotLiquidity(
        uint256 tokenId,
        address poolAddress,
        int24 _tickLower,
        int24 _tickUpper
    );

    function setTokenIssue(ITokenIssue _tokenIssue) public onlyOwner {
        tokenIssue = _tokenIssue;
    }

    function setISummaSwapV3Manager(ISummaSwapV3Manager _ISummaSwapV3Manager)
        public
        onlyOwner
    {
        iSummaSwapV3Manager = _ISummaSwapV3Manager;
    }

    function setTotalIssueRate(uint256 _totalIssueRate) public onlyOwner {
        totalIssueRate = _totalIssueRate;
    }

    function setSettlementBlock(uint256 _settlementBlock) public onlyOwner {
        settlementBlock = _settlementBlock;
    }

    function setFactory(address _factory) public onlyOwner {
        factory = _factory;
    }

    function setRouterAddress(address _routerAddress) public onlyOwner {
        router = _routerAddress;
    }

    function setTradeShare(uint256 _tradeShare) public onlyOwner {
        tradeShare = _tradeShare;
    }

    function setPledgeRate(uint256 _pledgeRate) public onlyOwner {
        pledgeRate = _pledgeRate;
    }

    function setMinPledge(uint256 _minPledge) public onlyOwner {
        minPledge = _minPledge * 10**18;
    }

    function setSummaAddress(address _summaAddress) public onlyOwner {
        summaAddress = _summaAddress;
    }

    function setPriAddress(address _priAddress) public onlyOwner {
        priAddress = _priAddress;
    }

    function setReduceFee(uint24 _reduceFee) public onlyOwner {
        reduceFee = _reduceFee;
    }

    function setSuperFee(uint24 _superFee) public onlyOwner {
        superFee = _superFee;
    }

    function enableReward(
        address _poolAddress,
        bool _isReward,
        uint256 _rewardShare
    ) public onlyOwner {
        require(settlementBlock > 0, "error settlementBlock");
        massUpdatePools();
        if (_isReward) {
            require(_rewardShare > 0, "error rewardShare");
            PoolInfo storage _poolInfo = poolInfoByPoolAddress[_poolAddress];
            if (poolAddress.length == 0) {
                lastWithdrawBlock = block.number.div(settlementBlock).mul(
                    settlementBlock
                );
            }
            if (_poolInfo.poolAddress == address(0)) {
                _poolInfo.lastSettlementBlock = block
                    .number
                    .div(settlementBlock)
                    .mul(settlementBlock);
                poolAddress.push(_poolAddress);
            }
            totalRewardShare += _rewardShare;
            totalRewardShare -= _poolInfo.rewardShare;
            _poolInfo.poolAddress = _poolAddress;
            _poolInfo.rewardShare = _rewardShare;
        } else {
            require(isReward[_poolAddress], "pool is not reward");
            PoolInfo storage _poolInfo = poolInfoByPoolAddress[_poolAddress];
            totalRewardShare -= _poolInfo.rewardShare;
            _poolInfo.rewardShare = 0;
        }
        isReward[_poolAddress] = _isReward;
    }

    function enableReward(
        address token0,
        address token1,
        uint24 fee,
        bool _isReward,
        uint256 _rewardShare
    ) public onlyOwner {
        require(settlementBlock > 0, "error settlementBlock");
        address _poolAddress = PoolAddress.computeAddress(
            factory,
            token0,
            token1,
            fee
        );
        massUpdatePools();
        if (_isReward) {
            require(_rewardShare > 0, "error rewardShare");
            PoolInfo storage _poolInfo = poolInfoByPoolAddress[_poolAddress];
            if (poolAddress.length == 0) {
                lastWithdrawBlock = block.number.div(settlementBlock).mul(
                    settlementBlock
                );
            }
            if (_poolInfo.poolAddress == address(0)) {
                _poolInfo.lastSettlementBlock = block
                    .number
                    .div(settlementBlock)
                    .mul(settlementBlock);
                poolAddress.push(_poolAddress);
            }
            totalRewardShare += _rewardShare;
            totalRewardShare -= _poolInfo.rewardShare;
            _poolInfo.poolAddress = _poolAddress;
            _poolInfo.rewardShare = _rewardShare;
        } else {
            require(isReward[_poolAddress], "pool is not reward");
            PoolInfo storage _poolInfo = poolInfoByPoolAddress[_poolAddress];
            totalRewardShare -= _poolInfo.rewardShare;
            _poolInfo.rewardShare = 0;
        }
        isReward[_poolAddress] = _isReward;
    }

    function massUpdatePools() public {
        uint256 length = poolAddress.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    function updatePool(uint256 _pid) public {
        address _poolAddress = poolAddress[_pid];
        PoolInfo storage poolInfo = poolInfoByPoolAddress[_poolAddress];
        if (
            poolInfo.lastSettlementBlock.add(settlementBlock) <= block.number &&
            poolInfo.unSettlementAmount > 0
        ) {
            uint256 form = poolInfo.lastSettlementBlock;
            uint256 to = (form.add(settlementBlock));
            uint256 summaReward = getMultiplier(form, to)
                .mul(poolInfo.rewardShare)
                .div(totalRewardShare);
            settlementTrade(poolInfo.poolAddress, summaReward.div(tradeShare));
            settlementPoolNewLiquidityIncentiveGrowth(poolInfo.poolAddress);
            withdrawTokenFromPri();
        }
    }

    function withdrawSumma(uint256 amount) public onlyOwner {
        IERC20(summaAddress).safeTransfer(msg.sender, amount);
    }

    function pendingSumma(address userAddress) public view returns (uint256) {
        uint256 amount = 0;
        uint256 length = poolAddress.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            address _poolAddress = poolAddress[pid];
            PoolInfo storage poolInfo = poolInfoByPoolAddress[_poolAddress];
            UserInfo storage userInfo = userInfo[userAddress][_poolAddress];
            if (userInfo.lastTradeBlock != 0) {
                if (userInfo.lastTradeBlock < poolInfo.lastSettlementBlock) {
                    amount += FullMath.mulDiv(
                        userInfo.tradeUnSettlementedAmount,
                        poolInfo.tradeSettlementAmountGrowth[
                            (
                                userInfo
                                    .lastTradeBlock
                                    .div(settlementBlock)
                                    .add(1)
                            ).mul(settlementBlock)
                        ],
                        FixedPoint128.Q128
                    );
                } else if (
                    (userInfo.lastTradeBlock.div(settlementBlock).add(1)).mul(
                        settlementBlock
                    ) <=
                    block.number &&
                    poolInfo.unSettlementAmount > 0
                ) {
                    uint256 form = (
                        userInfo.lastTradeBlock.div(settlementBlock)
                    ).mul(settlementBlock);
                    uint256 to = form.add(settlementBlock);
                    uint256 summaReward = getMultiplier(form, to)
                        .mul(poolInfo.rewardShare)
                        .div(totalRewardShare);
                    uint256 tradeReward = (summaReward).div(tradeShare);
                    uint256 quotient = FullMath.mulDiv(
                        tradeReward,
                        FixedPoint128.Q128,
                        poolInfo.unSettlementAmount
                    );
                    amount += FullMath.mulDiv(
                        quotient,
                        userInfo.tradeUnSettlementedAmount,
                        FixedPoint128.Q128
                    );
                }
                amount += userInfo.tradeSettlementedAmount;
            }
        }
        uint256 balance = iSummaSwapV3Manager.balanceOf(userAddress);
        for (uint256 pid = 0; pid < balance; ++pid) {
            uint256 tokenId = iSummaSwapV3Manager.tokenOfOwnerByIndex(
                userAddress,
                pid
            );
            amount += getPendingSummaByTokenId(tokenId);
        }
        return amount;
    }

    function pendingTradeSumma(address userAddress)
        public
        view
        returns (uint256)
    {
        uint256 amount = 0;
        uint256 length = poolAddress.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            address _poolAddress = poolAddress[pid];
            PoolInfo storage poolInfo = poolInfoByPoolAddress[_poolAddress];
            UserInfo storage userInfo = userInfo[userAddress][poolAddress[pid]];
            if (userInfo.lastTradeBlock != 0) {
                if (userInfo.lastTradeBlock < poolInfo.lastSettlementBlock) {
                    amount += FullMath.mulDiv(
                        userInfo.tradeUnSettlementedAmount,
                        poolInfo.tradeSettlementAmountGrowth[
                            (
                                userInfo
                                    .lastTradeBlock
                                    .div(settlementBlock)
                                    .add(1)
                            ).mul(settlementBlock)
                        ],
                        FixedPoint128.Q128
                    );
                } else if (
                    (userInfo.lastTradeBlock.div(settlementBlock).add(1)).mul(
                        settlementBlock
                    ) <=
                    block.number &&
                    poolInfo.unSettlementAmount > 0
                ) {
                    uint256 form = (
                        userInfo.lastTradeBlock.div(settlementBlock)
                    ).mul(settlementBlock);
                    uint256 to = (
                        userInfo.lastTradeBlock.div(settlementBlock).add(1)
                    ).mul(settlementBlock);
                    uint256 summaReward = getMultiplier(form, to)
                        .mul(poolInfo.rewardShare)
                        .div(totalRewardShare);
                    uint256 tradeReward = (summaReward).div(tradeShare);
                    uint256 quotient = FullMath.mulDiv(
                        tradeReward,
                        FixedPoint128.Q128,
                        poolInfo.unSettlementAmount
                    );
                    amount += FullMath.mulDiv(
                        quotient,
                        userInfo.tradeUnSettlementedAmount,
                        FixedPoint128.Q128
                    );
                }
                amount += userInfo.tradeSettlementedAmount;
            }
        }
        return amount;
    }

    function getPendingSummaByTokenId(uint256 tokenId)
        public
        view
        returns (uint256)
    {
        uint256 amount = 0;
        (
            ,
            ,
            address token0,
            address token1,
            uint24 fee,
            int24 tickLower,
            int24 tickUpper,
            uint128 liquidity,
            ,
            ,
            ,

        ) = iSummaSwapV3Manager.positions(tokenId);
        address poolAddress = PoolAddress.computeAddress(
            factory,
            token0,
            token1,
            fee
        );
        if (isReward[poolAddress]) {
            (
                uint256 liquidityIncentiveGrowthInPosition,
                uint256 blockSettlementVolume
            ) = getLiquidityIncentiveGrowthInPosition(
                    tickLower,
                    tickUpper,
                    tokenId,
                    poolAddress
                );
            Position memory position = _positions[tokenId];
            uint256 userLastReward = position.lastRewardGrowthInside;
            if (position.lastRewardVolumeGrowth > 0) {
                userLastReward += FullMath.mulDiv(
                    position.lastRewardVolumeGrowth,
                    blockSettlementVolume,
                    FixedPoint128.Q128
                );
            }
            if (liquidityIncentiveGrowthInPosition > userLastReward) {
                uint256 newliquidityIncentiveGrowthInPosition = liquidityIncentiveGrowthInPosition
                        .sub(userLastReward);
                amount += FullMath.mulDiv(
                    newliquidityIncentiveGrowthInPosition,
                    liquidity,
                    FixedPoint128.Q128
                );
            }
            amount += position.tokensOwed;
        }
        return amount;
    }

    function getPoolReward(address poolAddress)
        internal
        view
        returns (uint256)
    {
        PoolInfo storage poolInfo = poolInfoByPoolAddress[poolAddress];
        uint256 form = poolInfo.lastSettlementBlock;
        uint256 to = poolInfo.lastSettlementBlock.add(settlementBlock);
        uint256 multiplier = getMultiplier(form, to);
        uint256 reward = multiplier
            .mul(poolInfo.rewardShare)
            .div(totalRewardShare)
            .div(tradeShare)
            .mul(tradeShare.sub(1));
        return reward;
    }

    function getLiquidityIncentiveGrowthInPosition(
        int24 _tickLower,
        int24 _tickUpper,
        uint256 tokenId,
        address poolAddress
    )
        public
        view
        returns (uint256 feeGrowthInside, uint256 blockSettlementVolume)
    {
        PoolInfo storage poolInfo = poolInfoByPoolAddress[poolAddress];
        uint256 newLiquidityIncentiveGrowth = poolInfo.liquidityIncentiveGrowth;
        if (
            poolInfo.lastSettlementBlock.add(settlementBlock) <= block.number &&
            poolInfo.unSettlementAmount > 0
        ) {
            (
                uint256 newSettlement,
                uint256 _blockSettlementVolume
            ) = getPoolNewLiquidityIncentiveGrowth(poolAddress);
            newLiquidityIncentiveGrowth += newSettlement;
            blockSettlementVolume = _blockSettlementVolume;
        }
        TickInfo storage tickLower = poolInfo.ticks[_tickLower];
        uint256 newLowerLiquidityIncentiveGrowthOutside = tickLower
            .liquidityIncentiveGrowthOutside;
        if (tickLower.liquidityVolumeGrowthOutside != 0) {
            if (
                poolInfo.blockSettlementVolume[tickLower.settlementBlock] != 0
            ) {
                newLowerLiquidityIncentiveGrowthOutside += FullMath.mulDiv(
                    tickLower.liquidityVolumeGrowthOutside,
                    poolInfo.blockSettlementVolume[tickLower.settlementBlock],
                    FixedPoint128.Q128
                );
            } else if (
                tickLower.settlementBlock ==
                poolInfo.lastSettlementBlock.add(settlementBlock)
            ) {
                newLowerLiquidityIncentiveGrowthOutside += FullMath.mulDiv(
                    tickLower.liquidityVolumeGrowthOutside,
                    blockSettlementVolume,
                    FixedPoint128.Q128
                );
            }
        }
        TickInfo storage tickUpper = poolInfo.ticks[_tickUpper];
        uint256 newUpLiquidityIncentiveGrowthOutside = tickUpper
            .liquidityIncentiveGrowthOutside;
        if (tickUpper.liquidityVolumeGrowthOutside != 0) {
            if (
                poolInfo.blockSettlementVolume[tickUpper.settlementBlock] != 0
            ) {
                newUpLiquidityIncentiveGrowthOutside += FullMath.mulDiv(
                    tickUpper.liquidityVolumeGrowthOutside,
                    poolInfo.blockSettlementVolume[tickUpper.settlementBlock],
                    FixedPoint128.Q128
                );
            } else if (
                tickUpper.settlementBlock ==
                poolInfo.lastSettlementBlock.add(settlementBlock)
            ) {
                newUpLiquidityIncentiveGrowthOutside += FullMath.mulDiv(
                    tickUpper.liquidityVolumeGrowthOutside,
                    blockSettlementVolume,
                    FixedPoint128.Q128
                );
            }
        }
        // calculate fee growth below
        uint256 feeGrowthBelow;
        if (poolInfo.currentTick >= _tickLower) {
            feeGrowthBelow = newLowerLiquidityIncentiveGrowthOutside;
        } else {
            feeGrowthBelow =
                newLiquidityIncentiveGrowth -
                newLowerLiquidityIncentiveGrowthOutside;
        }
        uint256 feeGrowthAbove;
        if (poolInfo.currentTick < _tickUpper) {
            feeGrowthAbove = newUpLiquidityIncentiveGrowthOutside;
        } else {
            feeGrowthAbove =
                newLiquidityIncentiveGrowth -
                newUpLiquidityIncentiveGrowthOutside;
        }
        feeGrowthInside =
            newLiquidityIncentiveGrowth -
            feeGrowthBelow -
            feeGrowthAbove;
        if (
            poolInfo.blockSettlementVolume[
                _positions[tokenId].lastRewardSettlementedBlock
            ] != 0
        ) {
            blockSettlementVolume = poolInfo.blockSettlementVolume[
                _positions[tokenId].lastRewardSettlementedBlock
            ];
        }
    }

    function settlementLiquidityIncentiveGrowthInPosition(
        int24 _tickLower,
        int24 _tickUpper,
        address poolAddress
    ) internal returns (uint256) {
        PoolInfo storage poolInfo = poolInfoByPoolAddress[poolAddress];
        uint256 newLiquidityIncentiveGrowth = poolInfo.liquidityIncentiveGrowth;
        if (
            poolInfo.lastSettlementBlock.add(settlementBlock) <= block.number &&
            poolInfo.unSettlementAmount > 0
        ) {
            newLiquidityIncentiveGrowth = settlementPoolNewLiquidityIncentiveGrowth(
                poolAddress
            );
        }
        if (newLiquidityIncentiveGrowth == 0) {
            return 0;
        }
        TickInfo storage tickLower = poolInfo.ticks[_tickLower];
        if (
            poolInfo.blockSettlementVolume[tickLower.settlementBlock] > 0 &&
            tickLower.liquidityVolumeGrowthOutside > 0
        ) {
            tickLower.liquidityIncentiveGrowthOutside += FullMath.mulDiv(
                tickLower.liquidityVolumeGrowthOutside,
                poolInfo.blockSettlementVolume[tickLower.settlementBlock],
                FixedPoint128.Q128
            );
            tickLower.liquidityVolumeGrowthOutside = 0;
        }
        uint256 newLowerLiquidityIncentiveGrowthOutside = tickLower
            .liquidityIncentiveGrowthOutside;
        TickInfo storage tickUpper = poolInfo.ticks[_tickUpper];
        if (
            poolInfo.blockSettlementVolume[tickUpper.settlementBlock] > 0 &&
            tickUpper.liquidityVolumeGrowthOutside > 0
        ) {
            tickUpper.liquidityIncentiveGrowthOutside += FullMath.mulDiv(
                tickUpper.liquidityVolumeGrowthOutside,
                poolInfo.blockSettlementVolume[tickUpper.settlementBlock],
                FixedPoint128.Q128
            );
            tickUpper.liquidityVolumeGrowthOutside = 0;
        }
        uint256 newUpLiquidityIncentiveGrowthOutside = tickUpper
            .liquidityIncentiveGrowthOutside;
        // calculate fee growth below
        uint256 feeGrowthBelow;
        if (poolInfo.currentTick >= _tickLower) {
            feeGrowthBelow = newLowerLiquidityIncentiveGrowthOutside;
        } else {
            feeGrowthBelow =
                newLiquidityIncentiveGrowth -
                newLowerLiquidityIncentiveGrowthOutside;
        }
        uint256 feeGrowthAbove;
        if (poolInfo.currentTick < _tickUpper) {
            feeGrowthAbove = newUpLiquidityIncentiveGrowthOutside;
        } else {
            feeGrowthAbove =
                newLiquidityIncentiveGrowth -
                newUpLiquidityIncentiveGrowthOutside;
        }
        uint256 feeGrowthInside = newLiquidityIncentiveGrowth -
            feeGrowthBelow -
            feeGrowthAbove;
        return feeGrowthInside;
    }

    function settlementPoolNewLiquidityIncentiveGrowth(address poolAddress)
        internal
        returns (uint256)
    {
        PoolInfo storage poolInfo = poolInfoByPoolAddress[poolAddress];
        uint256 reward = getPoolReward(poolAddress);
        poolInfo.liquidityIncentiveGrowth += reward
            .mul(poolInfo.liquidityVolumeGrowth)
            .div(poolInfo.unSettlementAmount);
        poolInfo.liquidityVolumeGrowth = 0;
        poolInfo.blockSettlementVolume[
            poolInfo.lastSettlementBlock.add(settlementBlock)
        ] = FullMath.mulDiv(
            reward,
            FixedPoint128.Q128,
            poolInfo.unSettlementAmount
        );
        poolInfo.unSettlementAmount = 0;
        poolInfo.lastSettlementBlock = block.number.div(settlementBlock).mul(
            settlementBlock
        );
        return poolInfo.liquidityIncentiveGrowth;
    }

    function getPoolNewLiquidityIncentiveGrowth(address poolAddress)
        public
        view
        returns (
            uint256 newLiquidityIncentiveGrowth,
            uint256 blockSettlementVolume
        )
    {
        PoolInfo storage poolInfo = poolInfoByPoolAddress[poolAddress];
        uint256 reward = getPoolReward(poolAddress);
        newLiquidityIncentiveGrowth = reward
            .mul(poolInfo.liquidityVolumeGrowth)
            .div(poolInfo.unSettlementAmount);
        blockSettlementVolume = FullMath.mulDiv(
            reward,
            FixedPoint128.Q128,
            poolInfo.unSettlementAmount
        );
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to)
        internal
        view
        returns (uint256)
    {
        uint256 issueTime = tokenIssue.startIssueTime();
        if (_to < issueTime) {
            return 0;
        }
        if (_from < issueTime) {
            return getIssue(issueTime, _to).mul(totalIssueRate).div(10000);
        }
        return
            getIssue(issueTime, _to)
                .sub(getIssue(issueTime, _from))
                .mul(totalIssueRate)
                .div(10000);
    }

    function withdrawTokenFromPri() internal {
        uint256 nowWithdrawBlock = block.number.div(settlementBlock).mul(
            settlementBlock
        );
        if (nowWithdrawBlock > lastWithdrawBlock) {
            uint256 summaReward = getMultiplier(
                lastWithdrawBlock,
                nowWithdrawBlock
            );
            tokenIssue.transByContract(address(this), summaReward);
        }
        lastWithdrawBlock = nowWithdrawBlock;
    }

    function withdraw() public {
        withdrawTokenFromPri();
        uint256 amount = withdrawSettlement();
        uint256 pledge = amount.mul(pledgeRate).div(100);
        if (pledge < minPledge) {
            pledge = minPledge;
        }
        if (pledge != 0) {
            require(
                IERC20(summaAddress).balanceOf(msg.sender) > pledge,
                "Insufficient pledge"
            );
        }
        IERC20(summaAddress).safeTransfer(address(msg.sender), amount);
    }

    function withdrawByTokenId(uint256 tokenId) public {
        withdrawTokenFromPri();
        require(msg.sender == iSummaSwapV3Manager.ownerOf(tokenId),"not allowed!");
        uint256 amount = withdrawSettlementByTokenId(tokenId);
        uint256 pledge = amount.mul(pledgeRate).div(100);
        if (pledge < minPledge) {
            pledge = minPledge;
        }
        if (pledge != 0) {
            require(
                IERC20(summaAddress).balanceOf(msg.sender) > pledge,
                "Insufficient pledge"
            );
        }
        IERC20(summaAddress).safeTransfer(address(msg.sender), amount);
    }

    function withdrawTrade() public {
        withdrawTokenFromPri();
        uint256 amount = withdrawSettlementTrade();
        uint256 pledge = amount.mul(pledgeRate).div(100);
        if (pledge < minPledge) {
            pledge = minPledge;
        }
        if (pledge != 0) {
            require(
                IERC20(summaAddress).balanceOf(msg.sender) > pledge,
                "Insufficient pledge"
            );
        }
        IERC20(summaAddress).safeTransfer(address(msg.sender), amount);
    }

    function withdrawSettlementTrade() internal returns (uint256) {
        uint256 amount = 0;
        uint256 length = poolAddress.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            address _poolAddress = poolAddress[pid];
            PoolInfo storage poolInfo = poolInfoByPoolAddress[_poolAddress];
            UserInfo storage userInfo = userInfo[msg.sender][poolAddress[pid]];
            if (
                poolInfo.lastSettlementBlock.add(settlementBlock) <=
                block.number &&
                poolInfo.unSettlementAmount > 0
            ) {
                uint256 form = poolInfo.lastSettlementBlock;
                uint256 to = poolInfo.lastSettlementBlock.add(settlementBlock);
                uint256 summaReward = getMultiplier(form, to)
                    .mul(poolInfo.rewardShare)
                    .div(totalRewardShare);
                poolInfo.tradeSettlementAmountGrowth[to] += FullMath.mulDiv(
                    summaReward.div(tradeShare),
                    FixedPoint128.Q128,
                    poolInfo.unSettlementAmount
                );
                settlementPoolNewLiquidityIncentiveGrowth(poolInfo.poolAddress);
            }
            uint256 tradeSettlementAmount = poolInfo
                .tradeSettlementAmountGrowth[
                    userInfo
                        .lastTradeBlock
                        .div(settlementBlock)
                        .mul(settlementBlock)
                        .add(settlementBlock)
                ];
            if (
                userInfo.tradeUnSettlementedAmount != 0 &&
                tradeSettlementAmount != 0
            ) {
                userInfo.tradeSettlementedAmount += FullMath.mulDiv(
                    userInfo.tradeUnSettlementedAmount,
                    tradeSettlementAmount,
                    FixedPoint128.Q128
                );
                userInfo.tradeUnSettlementedAmount = 0;
            }
            amount += userInfo.tradeSettlementedAmount;
            userInfo.tradeSettlementedAmount = 0;
        }
        return amount;
    }

    function settlementTrade(
        address tradeAddress,
        address poolAddress,
        uint256 summaReward
    ) internal {
        UserInfo storage userInfo = userInfo[tradeAddress][poolAddress];
        PoolInfo storage poolInfo = poolInfoByPoolAddress[poolAddress];
        poolInfo.tradeSettlementAmountGrowth[
            poolInfo.lastSettlementBlock.add(settlementBlock)
        ] += FullMath.mulDiv(
            summaReward,
            FixedPoint128.Q128,
            poolInfo.unSettlementAmount
        );
        userInfo.tradeSettlementedAmount += FullMath.mulDiv(
            userInfo.tradeUnSettlementedAmount,
            poolInfo.tradeSettlementAmountGrowth[
                (userInfo.lastTradeBlock.div(settlementBlock).add(1)).mul(
                    settlementBlock
                )
            ],
            FixedPoint128.Q128
        );
        userInfo.tradeUnSettlementedAmount = 0;
    }

    function settlementTrade(address poolAddress, uint256 summaReward)
        internal
    {
        PoolInfo storage poolInfo = poolInfoByPoolAddress[poolAddress];
        poolInfo.tradeSettlementAmountGrowth[
            poolInfo.lastSettlementBlock.add(settlementBlock)
        ] += FullMath.mulDiv(
            summaReward,
            FixedPoint128.Q128,
            poolInfo.unSettlementAmount
        );
    }

    function withdrawSettlement() internal returns (uint256) {
        uint256 amount = 0;
        uint256 length = poolAddress.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            address _poolAddress = poolAddress[pid];
            PoolInfo storage poolInfo = poolInfoByPoolAddress[_poolAddress];
            UserInfo storage userInfo = userInfo[msg.sender][poolAddress[pid]];
            if (
                poolInfo.lastSettlementBlock.add(settlementBlock) <=
                block.number &&
                poolInfo.unSettlementAmount > 0
            ) {
                uint256 form = poolInfo.lastSettlementBlock;
                uint256 to = poolInfo.lastSettlementBlock.add(settlementBlock);
                uint256 summaReward = getMultiplier(form, to)
                    .mul(poolInfo.rewardShare)
                    .div(totalRewardShare);
                poolInfo.tradeSettlementAmountGrowth[to] += FullMath.mulDiv(
                    summaReward.div(tradeShare),
                    FixedPoint128.Q128,
                    poolInfo.unSettlementAmount
                );
                settlementPoolNewLiquidityIncentiveGrowth(poolInfo.poolAddress);
            }
            uint256 tradeSettlementAmount = poolInfo
                .tradeSettlementAmountGrowth[
                    userInfo
                        .lastTradeBlock
                        .div(settlementBlock)
                        .mul(settlementBlock)
                        .add(settlementBlock)
                ];
            if (
                userInfo.tradeUnSettlementedAmount != 0 &&
                tradeSettlementAmount != 0
            ) {
                userInfo.tradeSettlementedAmount += FullMath.mulDiv(
                    userInfo.tradeUnSettlementedAmount,
                    tradeSettlementAmount,
                    FixedPoint128.Q128
                );
                userInfo.tradeUnSettlementedAmount = 0;
            }
            amount += userInfo.tradeSettlementedAmount;
            userInfo.tradeSettlementedAmount = 0;
        }
        uint256 balance = iSummaSwapV3Manager.balanceOf(msg.sender);

        for (uint256 pid = 0; pid < balance; ++pid) {
            uint256 tokenId = iSummaSwapV3Manager.tokenOfOwnerByIndex(
                msg.sender,
                pid
            );
            amount += settlementByTokenId(tokenId);
        }
        return amount;
    }

    function withdrawSettlementByTokenId(uint256 tokenId)
        internal
        returns (uint256)
    {
        uint256 amount = 0;
        uint256 length = poolAddress.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            address _poolAddress = poolAddress[pid];
            PoolInfo storage poolInfo = poolInfoByPoolAddress[_poolAddress];
            UserInfo storage userInfo = userInfo[msg.sender][poolAddress[pid]];
            if (
                poolInfo.lastSettlementBlock.add(settlementBlock) <=
                block.number &&
                poolInfo.unSettlementAmount > 0
            ) {
                uint256 form = poolInfo.lastSettlementBlock;
                uint256 to = poolInfo.lastSettlementBlock.add(settlementBlock);
                uint256 summaReward = getMultiplier(form, to)
                    .mul(poolInfo.rewardShare)
                    .div(totalRewardShare);
                poolInfo.tradeSettlementAmountGrowth[to] += FullMath.mulDiv(
                    summaReward.div(tradeShare),
                    FixedPoint128.Q128,
                    poolInfo.unSettlementAmount
                );
                settlementPoolNewLiquidityIncentiveGrowth(poolInfo.poolAddress);
            }
            uint256 tradeSettlementAmount = poolInfo
                .tradeSettlementAmountGrowth[
                    userInfo
                        .lastTradeBlock
                        .div(settlementBlock)
                        .mul(settlementBlock)
                        .add(settlementBlock)
                ];
            if (
                userInfo.tradeUnSettlementedAmount != 0 &&
                tradeSettlementAmount != 0
            ) {
                userInfo.tradeSettlementedAmount += FullMath.mulDiv(
                    userInfo.tradeUnSettlementedAmount,
                    tradeSettlementAmount,
                    FixedPoint128.Q128
                );
                userInfo.tradeUnSettlementedAmount = 0;
            }
        }
        amount += settlementByTokenId(tokenId);
        return amount;
    }

    function settlementByTokenId(uint256 tokenId) internal returns (uint256) {
        (
            ,
            ,
            address token0,
            address token1,
            uint24 fee,
            int24 tickLower,
            int24 tickUpper,
            uint128 liquidity,
            ,
            ,
            ,

        ) = iSummaSwapV3Manager.positions(tokenId);
        address poolAddress = PoolAddress.computeAddress(
            factory,
            token0,
            token1,
            fee
        );
        uint256 amount = 0;
        if (isReward[poolAddress] ) {
            uint256 newLiquidityIncentiveGrowthInPosition = settlementLiquidityIncentiveGrowthInPosition(
                    tickLower,
                    tickUpper,
                    poolAddress
                );
            uint256 userLastReward = settlementLastReward(poolAddress, tokenId);
            amount += _positions[tokenId].tokensOwed;
            _positions[tokenId].tokensOwed = 0;
            if (newLiquidityIncentiveGrowthInPosition > userLastReward) {
                uint256 liquidityIncentiveGrowthInPosition = newLiquidityIncentiveGrowthInPosition
                        .sub(userLastReward);
                _positions[tokenId]
                    .lastRewardGrowthInside = newLiquidityIncentiveGrowthInPosition;
                amount += FullMath.mulDiv(
                    liquidityIncentiveGrowthInPosition,
                    liquidity,
                    FixedPoint128.Q128
                );
            } else {
                _positions[tokenId]
                    .lastRewardGrowthInside = newLiquidityIncentiveGrowthInPosition;
            }
        }
        return amount;
    }

    function settlementLastReward(address poolAddress, uint256 tokenId)
        internal
        returns (uint256 userLastReward)
    {
        PoolInfo storage poolInfo = poolInfoByPoolAddress[poolAddress];
        userLastReward = _positions[tokenId].lastRewardGrowthInside;
        if (
            _positions[tokenId].lastRewardVolumeGrowth >= 0 &&
            poolInfo.blockSettlementVolume[
                _positions[tokenId].lastRewardSettlementedBlock
            ] !=
            0
        ) {
            userLastReward += (
                FullMath.mulDiv(
                    _positions[tokenId].lastRewardVolumeGrowth,
                    poolInfo.blockSettlementVolume[
                        _positions[tokenId].lastRewardSettlementedBlock
                    ],
                    FixedPoint128.Q128
                )
            );
            _positions[tokenId].lastRewardVolumeGrowth = 0;
        }
    }

    function getIssue(uint256 _from, uint256 _to)
        private
        view
        returns (uint256)
    {
        if (_to <= _from || _from <= 0) {
            return 0;
        }
        uint256 timeInterval = _to - _from;
        uint256 monthIndex = timeInterval.div(tokenIssue.MONTH_SECONDS());
        if (monthIndex < 1) {
            return
                timeInterval.mul(
                    tokenIssue.issueInfo(monthIndex).div(
                        tokenIssue.MONTH_SECONDS()
                    )
                );
        } else if (monthIndex < tokenIssue.issueInfoLength()) {
            uint256 tempTotal = 0;
            for (uint256 j = 0; j < monthIndex; j++) {
                tempTotal = tempTotal.add(tokenIssue.issueInfo(j));
            }
            uint256 calcAmount = timeInterval
                .sub(monthIndex.mul(tokenIssue.MONTH_SECONDS()))
                .mul(
                    tokenIssue.issueInfo(monthIndex).div(
                        tokenIssue.MONTH_SECONDS()
                    )
                )
                .add(tempTotal);
            if (
                calcAmount >
                tokenIssue.TOTAL_AMOUNT().sub(tokenIssue.INIT_MINE_SUPPLY())
            ) {
                return
                    tokenIssue.TOTAL_AMOUNT().sub(
                        tokenIssue.INIT_MINE_SUPPLY()
                    );
            }
            return calcAmount;
        } else {
            return 0;
        }
    }

    function cross(int24 _tick, int24 _nextTick) external override {
        require(Address.isContract(_msgSender()));
        PoolInfo storage poolInfo = poolInfoByPoolAddress[_msgSender()];
        if (isReward[_msgSender()]) {
            poolInfo.currentTick = _nextTick;
            TickInfo storage tick = poolInfo.ticks[_tick];
            if (
                tick.liquidityVolumeGrowthOutside > 0 &&
                poolInfo.blockSettlementVolume[tick.settlementBlock] > 0
            ) {
                tick.liquidityIncentiveGrowthOutside += FullMath.mulDiv(
                    poolInfo.blockSettlementVolume[tick.settlementBlock],
                    tick.liquidityVolumeGrowthOutside,
                    FixedPoint128.Q128
                );
                tick.liquidityVolumeGrowthOutside = 0;
            }
            tick.liquidityIncentiveGrowthOutside = poolInfo
                .liquidityIncentiveGrowth
                .sub(tick.liquidityIncentiveGrowthOutside);
            tick.liquidityVolumeGrowthOutside = poolInfo
                .liquidityVolumeGrowth
                .sub(tick.liquidityVolumeGrowthOutside);
            tick.settlementBlock = (block.number.div(settlementBlock).add(1))
                .mul(settlementBlock);
            emit Cross(
                _tick,
                _nextTick,
                poolInfo.liquidityVolumeGrowth,
                poolInfo.liquidityIncentiveGrowth,
                tick.liquidityVolumeGrowthOutside,
                tick.liquidityIncentiveGrowthOutside
            );
        }
    }

    function snapshot(
        bytes calldata _data,
        int24 tick,
        uint256 liquidityVolumeGrowth,
        uint256 tradeVolume
    ) external override {
        require(Address.isContract(_msgSender()));
        TradeMintCallbackData memory data = abi.decode(
            _data,
            (TradeMintCallbackData)
        );
        PoolInfo storage poolInfo = poolInfoByPoolAddress[_msgSender()];
        UserInfo storage userInfo = userInfo[data.realplay][_msgSender()];
        if (isReward[_msgSender()]) {
            if (
                poolInfo.lastSettlementBlock.add(settlementBlock) <=
                block.number &&
                poolInfo.unSettlementAmount > 0
            ) {
                uint256 form = poolInfo.lastSettlementBlock;
                uint256 to = (form.add(settlementBlock));
                uint256 summaReward = getMultiplier(form, to)
                    .mul(poolInfo.rewardShare)
                    .div(totalRewardShare);
                settlementTrade(
                    data.realplay,
                    _msgSender(),
                    summaReward.div(tradeShare)
                );
                settlementPoolNewLiquidityIncentiveGrowth(_msgSender());
            } else {
                uint256 tradeSettlementAmount = poolInfo
                    .tradeSettlementAmountGrowth[
                        userInfo
                            .lastTradeBlock
                            .div(settlementBlock)
                            .mul(settlementBlock)
                            .add(settlementBlock)
                    ];
                if (
                    userInfo.tradeUnSettlementedAmount != 0 &&
                    tradeSettlementAmount != 0
                ) {
                    userInfo.tradeSettlementedAmount += FullMath.mulDiv(
                        userInfo.tradeUnSettlementedAmount,
                        tradeSettlementAmount,
                        FixedPoint128.Q128
                    );
                    userInfo.tradeUnSettlementedAmount = 0;
                }
            }
            userInfo.tradeUnSettlementedAmount += tradeVolume;
            userInfo.lastTradeBlock = block.number;
            poolInfo.currentTick = tick;
            poolInfo.liquidityVolumeGrowth += liquidityVolumeGrowth;
            poolInfo.unSettlementAmount += tradeVolume;
            poolInfo.lastSettlementBlock = block
                .number
                .div(settlementBlock)
                .mul(settlementBlock);
            emit Snapshot(
                data.realplay,
                tick,
                liquidityVolumeGrowth,
                tradeVolume
            );
        }
    }

    function snapshotLiquidity(
        address poolAddress,
        uint128 liquidity,
        uint256 tokenId,
        int24 _tickLower,
        int24 _tickUpper
    ) external override {
        require(_msgSender() == address(iSummaSwapV3Manager));
        PoolInfo storage poolInfo = poolInfoByPoolAddress[poolAddress];
        if (isReward[poolAddress]) {
            if (
                poolInfo.lastSettlementBlock.add(settlementBlock) <=
                block.number &&
                poolInfo.unSettlementAmount > 0
            ) {
                uint256 form = poolInfo.lastSettlementBlock;
                uint256 to = (form.add(settlementBlock));
                uint256 summaReward = getMultiplier(form, to)
                    .mul(poolInfo.rewardShare)
                    .div(totalRewardShare);
                settlementTrade(poolAddress, summaReward.div(tradeShare));
            }
            settlementByTokenId(
                tokenId,
                poolAddress,
                liquidity,
                _tickLower,
                _tickUpper
            );
            emit SnapshotLiquidity(
                tokenId,
                poolAddress,
                _tickLower,
                _tickUpper
            );
        }
    }

    function snapshotMintLiquidity(
        address poolAddress,
        uint256 tokenId,
        int24 _tickLower,
        int24 _tickUpper
    ) external override {
        require(_msgSender() == address(iSummaSwapV3Manager));
        PoolInfo storage poolInfo = poolInfoByPoolAddress[poolAddress];
        if (isReward[poolAddress]) {
            if (
                poolInfo.lastSettlementBlock.add(settlementBlock) <=
                block.number &&
                poolInfo.unSettlementAmount > 0
            ) {
                uint256 form = poolInfo.lastSettlementBlock;
                uint256 to = (form.add(settlementBlock));
                uint256 summaReward = getMultiplier(form, to)
                    .mul(poolInfo.rewardShare)
                    .div(totalRewardShare);
                settlementTrade(poolAddress, summaReward.div(tradeShare));
            }
            settlementByTokenId(
                tokenId,
                poolAddress,
                0,
                _tickLower,
                _tickUpper
            );
            emit SnapshotMintLiquidity(
                tokenId,
                poolAddress,
                _tickLower,
                _tickUpper
            );
        }
    }

    function settlementByTokenId(
        uint256 tokenId,
        address poolAddress,
        uint128 liquidity,
        int24 _tickLower,
        int24 _tickUpper
    ) internal {
        Position storage position = _positions[tokenId];
        uint256 newLiquidityIncentiveGrowthInPosition = settlementLiquidityIncentiveGrowthInPosition(
                _tickLower,
                _tickUpper,
                poolAddress
            );
        uint256 userLastReward = settlementLastReward(poolAddress, tokenId);
        if (newLiquidityIncentiveGrowthInPosition > userLastReward) {
            uint256 liquidityIncentiveGrowthInPosition = newLiquidityIncentiveGrowthInPosition
                    .sub(userLastReward);
            if (liquidity != 0) {
                position.tokensOwed += FullMath.mulDiv(
                    liquidityIncentiveGrowthInPosition,
                    liquidity,
                    FixedPoint128.Q128
                );
            }
        }
        position.lastRewardGrowthInside = newLiquidityIncentiveGrowthInPosition;
        position
            .lastRewardVolumeGrowth = settlementLiquidityVolumeGrowthInPosition(
            _tickLower,
            _tickUpper,
            poolAddress
        );
        position.lastRewardSettlementedBlock = block
            .number
            .div(settlementBlock)
            .mul(settlementBlock)
            .add(settlementBlock);
    }

    function settlementLiquidityVolumeGrowthInPosition(
        int24 _tickLower,
        int24 _tickUpper,
        address poolAddress
    ) internal returns (uint256) {
        PoolInfo storage poolInfo = poolInfoByPoolAddress[poolAddress];
        if (poolInfo.liquidityVolumeGrowth == 0) {
            return 0;
        }
        TickInfo storage tickLower = poolInfo.ticks[_tickLower];
        TickInfo storage tickUpper = poolInfo.ticks[_tickUpper];
        // calculate fee growth below
        uint256 feeGrowthBelow;
        if (poolInfo.currentTick >= _tickLower) {
            feeGrowthBelow = tickLower.liquidityVolumeGrowthOutside;
        } else {
            feeGrowthBelow =
                poolInfo.liquidityVolumeGrowth -
                tickLower.liquidityVolumeGrowthOutside;
        }
        uint256 feeGrowthAbove;
        if (poolInfo.currentTick < _tickUpper) {
            feeGrowthAbove = tickUpper.liquidityVolumeGrowthOutside;
        } else {
            feeGrowthAbove =
                poolInfo.liquidityVolumeGrowth -
                tickUpper.liquidityVolumeGrowthOutside;
        }
        uint256 feeGrowthInside = poolInfo.liquidityVolumeGrowth -
            feeGrowthBelow -
            feeGrowthAbove;
        return feeGrowthInside;
    }

    function getFee(
        address tradeAddress,
        bytes calldata _data,
        uint24 fee
    ) external view override returns (uint24) {
        uint24 newfee = 0;
        if (Address.isContract(tradeAddress)) {
            TradeMintCallbackData memory data = abi.decode(
                _data,
                (TradeMintCallbackData)
            );
            newfee = fee;
            if (ISummaPri(priAddress).hasRole(PUBLIC_ROLE, data.realplay)) {
                newfee = fee - (fee / reduceFee);
            }
        } else {
            newfee = fee;
            if (ISummaPri(priAddress).hasRole(PUBLIC_ROLE, tradeAddress)) {
                newfee = fee - (fee / reduceFee);
            }
        }

        return newfee;
    }

    function getRelation(address tradeAddress, bytes calldata _data)
        external
        view
        override
        returns (address)
    {
        if (Address.isContract(tradeAddress)) {
            TradeMintCallbackData memory data = abi.decode(
                _data,
                (TradeMintCallbackData)
            );
            return ISummaPri(priAddress).getRelation(data.realplay);
        } else {
            return ISummaPri(priAddress).getRelation(tradeAddress);
        }
    }

    function getPledge(address userAddess) external view returns (uint256) {
        uint256 amount = pendingSumma(userAddess);
        uint256 pledge = amount.mul(pledgeRate).div(100);
        if (pledge < minPledge) {
            pledge = minPledge;
        }
        return pledge;
    }

    function getSuperFee() external view override returns (uint24) {
        return superFee;
    }

    function routerAddress() external view override returns (address) {
        return router;
    }

    function getPoolLength() external view returns (uint256) {
        return poolAddress.length;
    }

    function getPoolReward(address poolAddress, uint256 blockNum)
        external
        view
        returns (uint256 lpReward, uint256 tradeReward)
    {
        PoolInfo storage poolInfo = poolInfoByPoolAddress[poolAddress];
        uint256 form = blockNum.sub(settlementBlock);
        uint256 to = blockNum;
        uint256 summaReward = getMultiplier(form, to)
            .mul(poolInfo.rewardShare)
            .div(totalRewardShare);
        tradeReward = summaReward.div(tradeShare);
        lpReward = summaReward.sub(tradeReward);
    }

    function getTradeSettlementAmountGrowth(
        address poolAddress,
        uint256 blockNum
    ) external view returns (uint256 tradeSettlementAmountGrowth) {
        PoolInfo storage poolInfo = poolInfoByPoolAddress[poolAddress];
        tradeSettlementAmountGrowth = poolInfo.tradeSettlementAmountGrowth[
            blockNum
        ];
    }

    function getTickLiquidityIncentiveGrowthOutside(
        address poolAddress,
        int24 _tick
    )
        external
        view
        returns (
            uint256 liquidityIncentiveGrowthOutside,
            uint256 liquidityVolumeGrowthOutside,
            uint256 settlementBlock
        )
    {
        PoolInfo storage poolInfo = poolInfoByPoolAddress[poolAddress];
        TickInfo storage tick = poolInfo.ticks[_tick];
        liquidityIncentiveGrowthOutside = tick.liquidityIncentiveGrowthOutside;
        liquidityVolumeGrowthOutside = tick.liquidityVolumeGrowthOutside;
        settlementBlock = tick.settlementBlock;
    }

    function getReduceFeeByUserAddress(address usderAddress)
        external
        view
        returns (uint256)
    {
        if (ISummaPri(priAddress).hasRole(PUBLIC_ROLE, usderAddress)) {
            return reduceFee;
        } else {
            return 0;
        }
    }
}
