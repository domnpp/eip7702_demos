// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test, console2} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";
import {HelperApproveAndSwap} from "../src/HelperApproveAndSwap.sol";
import "./CommonForTests.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

contract MockERC20 is ERC20 {
    constructor() ERC20("Mock Token", "MOCK") {}

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

contract BatchCallAndSponsorTest is Test {
    // The contract that Alice will delegate execution to.
    HelperApproveAndSwap public implementation;

    // ERC-20 token contract for minting test tokens.
    MockERC20 public token;

    event CallExecuted(address indexed to, uint256 value, bytes data);
    event BatchExecuted(uint256 indexed nonce, HelperApproveAndSwap.Call[] calls);

    function setUp() public {
        // Deploy the delegation contract (Alice will delegate calls to this contract).
        implementation = new HelperApproveAndSwap();

        // Deploy an ERC-20 token contract where Alice is the minter.
        token = new MockERC20();

        // Fund accounts
        vm.deal(TestsConsts.ALICE_ADDRESS, 10 ether);
        token.mint(TestsConsts.ALICE_ADDRESS, 1000e18);
    }

    function testDirectExecution() public {
        console2.log("Sending 1 ETH from Alice to Bob and transferring 100 tokens to Bob in a single transaction");
        HelperApproveAndSwap.Call[] memory calls = new HelperApproveAndSwap.Call[](2);

        // ETH transfer
        calls[0] = HelperApproveAndSwap.Call({to: TestsConsts.BOB_ADDRESS, value: 1 ether, data: ""});

        // Token transfer
        calls[1] = HelperApproveAndSwap.Call({
            to: address(token),
            value: 0,
            data: abi.encodeCall(ERC20.transfer, (TestsConsts.BOB_ADDRESS, 100e18))
        });

        vm.signAndAttachDelegation(address(implementation), TestsConsts.ALICE_PK);

        vm.startPrank(TestsConsts.ALICE_ADDRESS);
        HelperApproveAndSwap(TestsConsts.ALICE_ADDRESS).execute(calls);
        vm.stopPrank();

        assertEq(TestsConsts.BOB_ADDRESS.balance, 1 ether);
        assertEq(token.balanceOf(TestsConsts.BOB_ADDRESS), 100e18);
    }

    function testSponsoredExecution() public {
        console2.log("Sending 1 ETH from Alice to a random address while the transaction is sponsored by Bob");

        HelperApproveAndSwap.Call[] memory calls = new HelperApproveAndSwap.Call[](1);
        address recipient = makeAddr("recipient");

        calls[0] = HelperApproveAndSwap.Call({to: recipient, value: 1 ether, data: ""});

        // Alice signs a delegation allowing `implementation` to execute transactions on her behalf.
        Vm.SignedDelegation memory signedDelegation = vm.signDelegation(address(implementation), TestsConsts.ALICE_PK);

        // Bob attaches the signed delegation from Alice and broadcasts it.
        vm.startBroadcast(TestsConsts.BOB_PK);
        vm.attachDelegation(signedDelegation);

        // Verify that Alice's account now temporarily behaves as a smart contract.
        bytes memory code = address(TestsConsts.ALICE_ADDRESS).code;
        require(code.length > 0, "no code written to Alice");
        // console2.log("Code on Alice's account:", vm.toString(code));

        // Debug nonce
        // console2.log("Nonce before sending transaction:", HelperApproveAndSwap(TestsConsts.ALICE_ADDRESS).nonce());

        bytes memory encodedCalls = "";
        for (uint256 i = 0; i < calls.length; i++) {
            encodedCalls = abi.encodePacked(encodedCalls, calls[i].to, calls[i].value, calls[i].data);
        }

        bytes32 digest = keccak256(abi.encodePacked(HelperApproveAndSwap(TestsConsts.ALICE_ADDRESS).nonce(), encodedCalls));

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(TestsConsts.ALICE_PK, MessageHashUtils.toEthSignedMessageHash(digest));
        bytes memory signature = abi.encodePacked(r, s, v);

        // Expect the event. The first parameter should be TestsConsts.BOB_ADDRESS.
        vm.expectEmit(true, true, true, true);
        emit HelperApproveAndSwap.CallExecuted(TestsConsts.BOB_ADDRESS, calls[0].to, calls[0].value, calls[0].data);

        // As Bob, execute the transaction via Alice's temporarily assigned contract.
        HelperApproveAndSwap(TestsConsts.ALICE_ADDRESS).execute(calls, signature);

        // console2.log("Nonce after sending transaction:", HelperApproveAndSwap(TestsConsts.ALICE_ADDRESS).nonce());

        vm.stopBroadcast();

        assertEq(recipient.balance, 1 ether);
    }

    function testWrongSignature() public {
        console2.log("Test wrong signature: Execution should revert with 'Invalid signature'.");
        HelperApproveAndSwap.Call[] memory calls = new HelperApproveAndSwap.Call[](1);
        calls[0] = HelperApproveAndSwap.Call({
            to: address(token),
            value: 0,
            data: abi.encodeCall(MockERC20.mint, (TestsConsts.BOB_ADDRESS, 50))
        });

        // Build the encoded call data.
        bytes memory encodedCalls = "";
        for (uint256 i = 0; i < calls.length; i++) {
            encodedCalls = abi.encodePacked(encodedCalls, calls[i].to, calls[i].value, calls[i].data);
        }

        // Alice signs a delegation allowing `implementation` to execute transactions on her behalf.
        Vm.SignedDelegation memory signedDelegation = vm.signDelegation(address(implementation), TestsConsts.ALICE_PK);

        // Bob attaches the signed delegation from Alice and broadcasts it.
        vm.startBroadcast(TestsConsts.BOB_PK);
        vm.attachDelegation(signedDelegation);

        bytes32 digest = keccak256(abi.encodePacked(HelperApproveAndSwap(TestsConsts.ALICE_ADDRESS).nonce(), encodedCalls));
        // Sign with the wrong key (Bob's instead of Alice's).
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(TestsConsts.BOB_PK, MessageHashUtils.toEthSignedMessageHash(digest));
        bytes memory signature = abi.encodePacked(r, s, v);

        vm.expectRevert("Invalid signature");
        HelperApproveAndSwap(TestsConsts.ALICE_ADDRESS).execute(calls, signature);
        vm.stopBroadcast();
    }

    function testReplayAttack() public {
        console2.log("Test replay attack: Reusing the same signature should revert.");
        HelperApproveAndSwap.Call[] memory calls = new HelperApproveAndSwap.Call[](1);
        calls[0] = HelperApproveAndSwap.Call({
            to: address(token),
            value: 0,
            data: abi.encodeCall(MockERC20.mint, (TestsConsts.BOB_ADDRESS, 30))
        });

        // Build encoded call data.
        bytes memory encodedCalls = "";
        for (uint256 i = 0; i < calls.length; i++) {
            encodedCalls = abi.encodePacked(encodedCalls, calls[i].to, calls[i].value, calls[i].data);
        }

        // Alice signs a delegation allowing `implementation` to execute transactions on her behalf.
        Vm.SignedDelegation memory signedDelegation = vm.signDelegation(address(implementation), TestsConsts.ALICE_PK);

        // Bob attaches the signed delegation from Alice and broadcasts it.
        vm.startBroadcast(TestsConsts.BOB_PK);
        vm.attachDelegation(signedDelegation);

        uint256 nonceBefore = HelperApproveAndSwap(TestsConsts.ALICE_ADDRESS).nonce();
        bytes32 digest = keccak256(abi.encodePacked(nonceBefore, encodedCalls));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(TestsConsts.ALICE_PK, MessageHashUtils.toEthSignedMessageHash(digest));
        bytes memory signature = abi.encodePacked(r, s, v);

        // First execution: should succeed.
        HelperApproveAndSwap(TestsConsts.ALICE_ADDRESS).execute(calls, signature);
        vm.stopBroadcast();

        // Attempt a replay: reusing the same signature should revert because nonce has incremented.
        vm.expectRevert("Invalid signature");
        HelperApproveAndSwap(TestsConsts.ALICE_ADDRESS).execute(calls, signature);
    }
}
