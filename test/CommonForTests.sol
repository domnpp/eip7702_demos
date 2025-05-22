// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

library TestsConsts
{
    // Alice's address and private key (EOA with no initial contract code).
    address constant ALICE_ADDRESS_CONST = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8;
    address payable constant ALICE_ADDRESS = payable(ALICE_ADDRESS_CONST);
    uint256 constant ALICE_PK = 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d;

    // Bob's address and private key (Bob will execute transactions on Alice's behalf).
    address constant BOB_ADDRESS = 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC;
    uint256 constant BOB_PK = 0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a;
}
