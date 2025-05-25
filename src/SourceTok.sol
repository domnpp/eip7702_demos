// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
// import {console} from "forge-std/Test.sol";

contract SourceTok is ERC20 {
    constructor() ERC20("DemoToken0", "DMT") {
     _mint(0x976EA74026E726554dB657fA54763abd0C3a0aa9, 4);
    }

    function mint(address to, uint256 amount) external {
        // console.log("MINT CALL");
        _mint(to, amount);
    }
}

contract RewardTok is ERC20 {
    SourceTok st;

    constructor(address t) ERC20("DemoToken1", "RWT") {
        st = SourceTok(t);
    }

    function reward(address to, uint256 amount) external {
        uint256 balance = st.balanceOf(to);
        // console.log("Transfer from ", to, ", amount: ", amount);
        // if (balance >= amount) {
            st.transferFrom(to, address(this), amount);
        // }

        _mint(to, amount);
    }
}
