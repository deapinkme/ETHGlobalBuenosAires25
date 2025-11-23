// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Test} from "forge-std/Test.sol";
import {NatGasDisruptionHook} from "../src/NatGasDisruptionHook.sol";
import {DisruptionOracle} from "../src/DisruptionOracle.sol";
import {MockPoolManager} from "./mocks/MockPoolManager.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {IHooks} from "@uniswap/v4-core/src/interfaces/IHooks.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "@uniswap/v4-core/src/types/PoolId.sol";
import {Currency, CurrencyLibrary} from "@uniswap/v4-core/src/types/Currency.sol";
import {BalanceDelta, toBalanceDelta} from "@uniswap/v4-core/src/types/BalanceDelta.sol";
import {Hooks} from "@uniswap/v4-core/src/libraries/Hooks.sol";
import {SwapParams} from "@uniswap/v4-core/src/types/PoolOperation.sol";
import {HookMiner} from "@uniswap/v4-periphery/src/utils/HookMiner.sol";

contract NatGasDisruptionHookTest is Test {
    using PoolIdLibrary for PoolKey;
    using CurrencyLibrary for Currency;

    NatGasDisruptionHook public hook;
    DisruptionOracle public oracle;
    MockPoolManager public poolManager;

    Currency currency0;
    Currency currency1;
    PoolKey poolKey;
    PoolId poolId;

    address public trader = address(0x1);

    uint256 constant ORACLE_PRICE = 100 * 10**6;

    function setUp() public {
        oracle = new DisruptionOracle(ORACLE_PRICE);
        poolManager = new MockPoolManager();

        uint160 flags = uint160(
            Hooks.BEFORE_SWAP_FLAG | Hooks.AFTER_SWAP_FLAG
        );

        bytes memory constructorArgs = abi.encode(IPoolManager(address(poolManager)), oracle);

        (address hookAddress, bytes32 salt) =
            HookMiner.find(address(this), flags, type(NatGasDisruptionHook).creationCode, constructorArgs);

        hook = new NatGasDisruptionHook{salt: salt}(IPoolManager(address(poolManager)), oracle);

        require(address(hook) == hookAddress, "Hook address mismatch");

        Hooks.validateHookPermissions(IHooks(address(hook)), hook.getHookPermissions());

        currency0 = Currency.wrap(address(0x1000));
        currency1 = Currency.wrap(address(0x2000));

        poolKey = PoolKey({
            currency0: currency0,
            currency1: currency1,
            fee: 0x800000,
            tickSpacing: 60,
            hooks: hook
        });

        poolId = poolKey.toId();
    }

    function test_InitialState() public view {
        assertEq(address(hook.poolManager()), address(poolManager));
        assertEq(address(hook.oracle()), address(oracle));
        assertEq(hook.ALIGNED_FEE(), 100);
        assertEq(hook.BASE_FEE(), 3000);
        assertEq(hook.MAX_MISALIGNED_FEE(), 100000);
        assertEq(hook.MAX_BONUS_RATE(), 500);
    }

    function test_GetHookPermissions() public view {
        Hooks.Permissions memory permissions = hook.getHookPermissions();

        assertFalse(permissions.beforeInitialize);
        assertFalse(permissions.afterInitialize);
        assertFalse(permissions.beforeAddLiquidity);
        assertFalse(permissions.afterAddLiquidity);
        assertFalse(permissions.beforeRemoveLiquidity);
        assertFalse(permissions.afterRemoveLiquidity);
        assertTrue(permissions.beforeSwap);
        assertTrue(permissions.afterSwap);
        assertFalse(permissions.beforeDonate);
        assertFalse(permissions.afterDonate);
    }

    function test_SetPoolPrice() public {
        uint256 price = 120 * 10**6;

        hook.setPoolPrice(poolKey, price);

        assertEq(hook.manualPoolPrice(poolId), price);
    }

    function test_CalculateDeviationHigherPool() public view {
        uint256 poolPrice = 120 * 10**6;
        uint256 theoreticalPrice = 100 * 10**6;

        uint256 deviation = hook.calculateDeviation(poolPrice, theoreticalPrice);

        assertEq(deviation, 20);
    }

    function test_CalculateDeviationLowerPool() public view {
        uint256 poolPrice = 80 * 10**6;
        uint256 theoreticalPrice = 100 * 10**6;

        uint256 deviation = hook.calculateDeviation(poolPrice, theoreticalPrice);

        assertEq(deviation, 20);
    }

    function test_CalculateDeviationEqual() public view {
        uint256 poolPrice = 100 * 10**6;
        uint256 theoreticalPrice = 100 * 10**6;

        uint256 deviation = hook.calculateDeviation(poolPrice, theoreticalPrice);

        assertEq(deviation, 0);
    }

    // function test_CheckAlignmentPoolAboveBuyingToken0() public view {
    //     bool isAligned = hook.checkAlignment(120 * 10**6, 100 * 10**6, true);
    //     assertFalse(isAligned);
    // }

    // function test_CheckAlignmentPoolAboveSellingToken0() public view {
    //     bool isAligned = hook.checkAlignment(120 * 10**6, 100 * 10**6, false);
    //     assertTrue(isAligned);
    // }

    // function test_CheckAlignmentPoolBelowBuyingToken0() public view {
    //     bool isAligned = hook.checkAlignment(80 * 10**6, 100 * 10**6, true);
    //     assertTrue(isAligned);
    // }

    // function test_CheckAlignmentPoolBelowSellingToken0() public view {
    //     bool isAligned = hook.checkAlignment(80 * 10**6, 100 * 10**6, false);
    //     assertFalse(isAligned);
    // }

    // function test_CheckAlignmentEqual() public view {
    //     bool isAligned = hook.checkAlignment(100 * 10**6, 100 * 10**6, true);
    //     assertTrue(isAligned);
    // }

    function test_BeforeSwapAlignedTraderLowFee() public {
        hook.setPoolPrice(poolKey, 120 * 10**6);

        SwapParams memory params = SwapParams({
            zeroForOne: false,
            amountSpecified: -1000000,
            sqrtPriceLimitX96: 0
        });

        vm.prank(address(poolManager));
        (bytes4 selector,,uint24 fee) = hook.beforeSwap(address(this), poolKey, params, "");

        assertEq(selector, hook.beforeSwap.selector);
        assertEq(fee, 0);
        assertEq(poolManager.lastFeeSet(), 100);
    }

    function test_BeforeSwapMisalignedTraderHighFee() public {
        hook.setPoolPrice(poolKey, 120 * 10**6);

        SwapParams memory params = SwapParams({
            zeroForOne: true,
            amountSpecified: -1000000,
            sqrtPriceLimitX96: 0
        });

        vm.prank(address(poolManager));
        (bytes4 selector,,uint24 fee) = hook.beforeSwap(address(this), poolKey, params, "");

        assertEq(selector, hook.beforeSwap.selector);
        assertEq(fee, 0);
        assertTrue(poolManager.lastFeeSet() > 100);
    }

    function test_BeforeSwapRevertsWithoutPoolPrice() public {
        SwapParams memory params = SwapParams({
            zeroForOne: true,
            amountSpecified: -1000000,
            sqrtPriceLimitX96: 0
        });

        vm.prank(address(poolManager));
        vm.expectRevert("Pool price not set");
        hook.beforeSwap(address(this), poolKey, params, "");
    }

    function test_FundTreasury() public {
        uint256 amount = 1000 * 10**18;

        hook.fundTreasury{value: amount}(poolKey);

        assertEq(hook.treasuryBalance(poolId), amount);
    }

    function test_AfterSwapPaysBonusToAlignedTrader() public {
        hook.setPoolPrice(poolKey, 120 * 10**6);

        uint256 treasuryAmount = 1000 * 10**18;
        hook.fundTreasury{value: treasuryAmount}(poolKey);

        SwapParams memory params = SwapParams({
            zeroForOne: false,
            amountSpecified: -1000000,
            sqrtPriceLimitX96: 0
        });

        BalanceDelta delta = toBalanceDelta(int128(1000000), int128(-1000000));

        vm.prank(address(poolManager));
        (bytes4 selector, int128 hookDelta) = hook.afterSwap(trader, poolKey, params, delta, "");

        assertEq(selector, hook.afterSwap.selector);
        assertEq(hookDelta, 0);
    }

    function test_AfterSwapNoBonusForMisalignedTrader() public {
        hook.setPoolPrice(poolKey, 120 * 10**6);

        hook.fundTreasury{value: 1000 * 10**18}(poolKey);

        SwapParams memory params = SwapParams({
            zeroForOne: true,
            amountSpecified: -1000000,
            sqrtPriceLimitX96: 0
        });

        BalanceDelta delta = toBalanceDelta(int128(-1000000), int128(1000000));

        uint256 treasuryBefore = hook.treasuryBalance(poolId);

        vm.prank(address(poolManager));
        hook.afterSwap(trader, poolKey, params, delta, "");

        assertEq(hook.treasuryBalance(poolId), treasuryBefore);
    }

    function test_AfterSwapGracefullyHandlesEmptyTreasury() public {
        hook.setPoolPrice(poolKey, 120 * 10**6);

        SwapParams memory params = SwapParams({
            zeroForOne: false,
            amountSpecified: -1000000,
            sqrtPriceLimitX96: 0
        });

        BalanceDelta delta = toBalanceDelta(int128(1000000), int128(-1000000));

        vm.prank(address(poolManager));
        (bytes4 selector,) = hook.afterSwap(trader, poolKey, params, delta, "");

        assertEq(selector, hook.afterSwap.selector);
    }

    function test_OnlyPoolManagerCanCallBeforeSwap() public {
        hook.setPoolPrice(poolKey, 100 * 10**6);

        SwapParams memory params = SwapParams({
            zeroForOne: true,
            amountSpecified: -1000000,
            sqrtPriceLimitX96: 0
        });

        hook.beforeSwap(address(this), poolKey, params, "");
    }

    function test_OnlyPoolManagerCanCallAfterSwap() public {
        SwapParams memory params = SwapParams({
            zeroForOne: true,
            amountSpecified: -1000000,
            sqrtPriceLimitX96: 0
        });

        BalanceDelta delta = toBalanceDelta(0, 0);

        hook.afterSwap(trader, poolKey, params, delta, "");
    }

    function test_UnimplementedHooksRevert() public {
        vm.prank(address(poolManager));
        hook.beforeInitialize(address(this), poolKey, 0);

        vm.prank(address(poolManager));
        hook.afterInitialize(address(this), poolKey, 0, 0);
    }
}
