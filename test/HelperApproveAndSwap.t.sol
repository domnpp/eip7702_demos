// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test, console2} from "forge-std/Test.sol";
import {RewardTok, SourceTok} from "../src/SourceTok.sol";
import {HelperApproveAndSwap} from "../src/HelperApproveAndSwap.sol";
import "./CommonForTests.sol";

contract HelperApproveAndSwapTest is Test {
    SourceTok public s;
    RewardTok public r;
    HelperApproveAndSwap public runner;

    function setUp() public {
        s = new SourceTok();
        r = new RewardTok(address(s));

        runner = new HelperApproveAndSwap();

        s.mint(address(runner), 1000);
    }

    // First test: pre-Pectra. "Alice" can't approve and swap in a single transaction. But Runner
    // (smart contract with batchReward function) can freely call it. Goal is to temporarily upgrade
    // Alice to gain capabilities of runner (HelperApproveAndSwap) to be able to call the function
    // and do 2 operations with a single transaction.
    function testCall() public {
        // Runner can freely call its own function. Runner has `s` tokens, so this function works.
        runner.batchReward(address(s), address(r), 16);
        assertEq(r.balanceOf(address(runner)), 16);

        // Alice must do 2 steps.
        s.mint(TestsConsts.ALICE_ADDRESS_CONST, 64);
        vm.startPrank(TestsConsts.ALICE_ADDRESS_CONST);
        s.approve(address(r), 64); // s can now spend up to 64 c
        r.reward(TestsConsts.ALICE_ADDRESS_CONST, 64);
        vm.stopPrank();
        assertEq(r.balanceOf(TestsConsts.ALICE_ADDRESS_CONST), 64);
    }

    // Copy paste the complicated (testDirectExecution) example and adapt it to our functions.
    function testErc7702Complicated() public
    {
        HelperApproveAndSwap.Call[] memory calls = new HelperApproveAndSwap.Call[](1);

        // Token transfer
        calls[0] = HelperApproveAndSwap.Call({
            to: TestsConsts.ALICE_ADDRESS,
            value: 0,
            data: abi.encodeCall(HelperApproveAndSwap.batchReward, (address(s), address(r), 64))
        });

        vm.signAndAttachDelegation(address(runner), TestsConsts.ALICE_PK);

        vm.startPrank(TestsConsts.ALICE_ADDRESS);
        HelperApproveAndSwap(TestsConsts.ALICE_ADDRESS).execute(calls);
        vm.stopPrank();

        assertEq(r.balanceOf(TestsConsts.ALICE_ADDRESS_CONST), 64);
    }

    // Simplify: Instead of encoding call that is done indirectly, just call the function.
    function testSimple() public {
        s.mint(TestsConsts.ALICE_ADDRESS_CONST, 64);
        assertEq(s.balanceOf(TestsConsts.ALICE_ADDRESS_CONST), 64);
        // Very important: Without this, the cast of ALICE to the contract will fail.
        vm.signAndAttachDelegation(address(runner), TestsConsts.ALICE_PK);
        console2.log("Start prank;");
        vm.startPrank(TestsConsts.ALICE_ADDRESS_CONST);
        HelperApproveAndSwap(TestsConsts.ALICE_ADDRESS_CONST).batchReward(address(s), address(r), 64);
        // Original example uses HelperApproveAndSwap(TestsConsts.ALICE_ADDRESS) where ALICE_ADDRESS
        // is payable. By removing receive() and fallback() from HelperApproveAndSwap, that isn't required.
        vm.stopPrank();

        assertEq(r.balanceOf(TestsConsts.ALICE_ADDRESS_CONST), 64);
        assertEq(s.balanceOf(TestsConsts.ALICE_ADDRESS_CONST), 0);
    }
}
