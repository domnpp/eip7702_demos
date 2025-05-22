// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract SimpleDelegateContract {
    struct Call {
        bytes data;
        address to;
        uint256 value;
    }

    event Executed(address indexed to, uint256 value, bytes data);

    function execute(Call[] memory calls) external payable {
        for (uint256 i = 0; i < calls.length; i++) {
            Call memory call = calls[i];
            (bool success,) = call.to.call{value: call.value}(call.data);
            require(success, "Call failed");
            emit Executed(call.to, call.value, call.data);
        }
    }

    receive() external payable {}
}

/*

Simple command line test

export ALICE_ADDRESS="0x70997970C51812dc3A010C7d01b50e0d17dc79C8"
export ALICE_PK="0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d"
export BOB_PK="0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a"
export SIMPLE_DELEGATE_ADDRESS=$(forge create SimpleDelegateContract --private-key $BOB_PK --broadcast | grep "Deployed to:" | awk '{print $3}')
cast code $ALICE_ADDRESS
SIGNED_AUTH=$(cast wallet sign-auth $SIMPLE_DELEGATE_ADDRESS --private-key $ALICE_PK)
cast send $ALICE_ADDRESS "execute((bytes,address,uint256)[])" "[("0x",$(cast az),0)]" --private-key $BOB_PK --auth $SIGNED_AUTH
cast code $ALICE_ADDRESS

With cancun we correctly get an Error: Failed to estimate gas: server returned an error response: error code -32003: EIP-7702 authorization lists are not supported before the Prague hardfork 

After cancun, the snippet runs without issues.
We expect the final output to be: 0xef0100...

*/
