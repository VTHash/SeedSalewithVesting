// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SeedSaleWithVesting is Ownable {
    struct Vesting {
        uint256 total;
        uint256 claimed;
        uint256 start;
    }

    IERC20 public immutable hfvToken;
    IERC20 public immutable usdcToken;

    uint256 public constant HFV_PRICE = 0.99 * 1e18; // $0.99 in 18 decimals
    uint256 public constant VESTING_DURATION = 180 days;
    uint256 public constant HFV_CAP = 2_100_000 * 1e18; // 2.1M HFV

    uint256 public totalSold;
    address public fundsReceiver;

    mapping(address => Vesting) public vestings;

    event Purchased(address indexed buyer, uint256 hfvAmount);
    event Claimed(address indexed buyer, uint256 amount);

    constructor(address _hfvToken, address _usdcToken, address _receiver) {
        hfvToken = IERC20(_hfvToken);
        usdcToken = IERC20(_usdcToken);
        fundsReceiver = _receiver;
    }

    function buyWithETH() external payable {
        require(msg.value > 0, "Zero ETH");

        // Fixed price: $0.99, assume ETH price = $X externally or define rate
        uint256 hfvAmount = (msg.value * 1e18) / HFV_PRICE;
        _processPurchase(msg.sender, hfvAmount);

        (bool sent, ) = payable(fundsReceiver).call{value: msg.value}();
        require(sent, "ETH transfer failed");
    }

    function buyWithUSDC(uint256 usdcAmount) external {
        require(usdcAmount > 0, "Zero USDC");

        uint256 hfvAmount = (usdcAmount * 1e18) / HFV_PRICE;
        _processPurchase(msg.sender, hfvAmount);

        require(usdcToken.transferFrom(msg.sender, fundsReceiver, usdcAmount), "USDC transfer failed");
    }

    function _processPurchase(address buyer, uint256 hfvAmount) internal {
        require(totalSold + hfvAmount <= HFV_CAP, "Exceeds cap");

        Vesting storage v = vestings[buyer];
        if (v.total == 0) {
            v.start = block.timestamp;
        }
        v.total += hfvAmount;
        totalSold += hfvAmount;

        emit Purchased(buyer, hfvAmount);
    }

    function claim() external {
        Vesting storage v = vestings[msg.sender];
        require(v.total > 0, "No tokens");

        uint256 elapsed = block.timestamp - v.start;
        if (elapsed > VESTING_DURATION) elapsed = VESTING_DURATION;

        uint256 claimable = (v.total * elapsed) / VESTING_DURATION - v.claimed;
        require(claimable > 0, "Nothing claimable");

        v.claimed += claimable;
        require(hfvToken.transfer(msg.sender, claimable), "Transfer failed");

        emit Claimed(msg.sender, claimable);
    }

    function setFundsReceiver(address newReceiver) external onlyOwner {
        fundsReceiver = newReceiver;
    }

    function withdrawUnsold() external onlyOwner {
        uint256 unsold = HFV_CAP - totalSold;
        require(hfvToken.transfer(owner(), unsold), "Withdraw failed");
    }
}
