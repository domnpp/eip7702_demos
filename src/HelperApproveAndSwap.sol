import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IDemo7702 {
    function reward(address to, uint256 amount) external;
}

contract HelperApproveAndSwap {
    function reward(
        address currency,
        address reward,
        uint256 amount
    ) external {
        IERC20 c = IERC20(currency);
        c.approve(reward, amount);
        IDemo7702(reward).reward(address(this), amount);
    }
}
