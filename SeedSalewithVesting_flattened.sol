// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor(address initialOwner) {
        require(initialOwner != address(0), "Owner is the zero address");
        _owner = initialOwner;
        emit OwnershipTransferred(address(0), initialOwner);
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == msg.sender, "Caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "New owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract SeedSaleWithVesting is Ownable {
    struct Vesting {
        uint256 total;
        uint256 claimed;
        uint256 start;
    }

    IERC20 public immutable hfvToken;
    IERC20 public immutable usdcToken;

    uint256 public constant HFV_PRICE = 0.99 * 1e18; // $0.99 per token
    uint256 public constant VESTING_DURATION = 180 days;
    uint256 public constant HFV_CAP = 2_100_000 * 1e18; // 2.1M HFV
    uint256 public constant MIN_ETH_PURCHASE = 250 * 1e18 / HFV_PRICE;
    uint256 public constant MAX_ETH_PURCHASE = 50000 * 1e18 / HFV_PRICE;

    uint256 public totalSold;
    address public fundsReceiver;

    mapping(address => Vesting) public vestings;
    mapping(address => uint256) public userTotalPurchased;

    event Purchased(address indexed buyer, uint256 hfvAmount);
    event Claimed(address indexed buyer, uint256 amount);

    constructor() Ownable(msg.sender) {
        hfvToken = IERC20(0xeAb3B66a24bD99171E0a854b6dA215CE3A7FFa98);
        usdcToken = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
        fundsReceiver = 0x746F338B11Fc1917A83ECF3c8c28CE318e4DAA51;
    }

    function buyWithETH() external payable {
        require(msg.value > 0, "Zero ETH");

        uint256 hfvAmount = (msg.value * 1e18) / HFV_PRICE;
        require(hfvAmount >= MIN_ETH_PURCHASE, "Below min purchase");
        require(userTotalPurchased[msg.sender] + hfvAmount <= MAX_ETH_PURCHASE, "Exceeds max per wallet");

        _processPurchase(msg.sender, hfvAmount);

        (bool sent, ) = payable(fundsReceiver).call{value: msg.value}("");
        require(sent, "ETH transfer failed");
    }

    function buyWithUSDC(uint256 usdcAmount) external {
        require(usdcAmount > 0, "Zero USDC");

        uint256 hfvAmount = (usdcAmount * 1e18) / HFV_PRICE;
        require(hfvAmount >= MIN_ETH_PURCHASE, "Below min purchase");
        require(userTotalPurchased[msg.sender] + hfvAmount <= MAX_ETH_PURCHASE, "Exceeds max per wallet");

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
        userTotalPurchased[buyer] += hfvAmount;

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
