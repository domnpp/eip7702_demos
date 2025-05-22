// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {RewardTok, SourceTok} from "../src/SourceTok.sol";
import {HelperApproveAndSwap} from "../src/HelperApproveAndSwap.sol";

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

    function testCall() public {
        runner.batchReward(address(s), address(r), 16);
        assertEq(r.balanceOf(address(runner)), 16);
    }
}
