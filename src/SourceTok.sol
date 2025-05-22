// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract SourceTok is ERC20 {
    constructor() ERC20("DemoToken0", "DMT") {
    }

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

contract RewardTok is ERC20 {
    SourceTok st;

    constructor(address t) ERC20("DemoToken1", "RWT") {
        st = SourceTok(t);
    }

    function reward(address to, uint256 amount) external {
        uint256 balance = st.balanceOf(msg.sender);

        if (balance >= amount) {
            st.transferFrom(msg.sender, address(this), amount);
        }

        _mint(to, amount);
    }
}
