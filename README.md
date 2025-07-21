# 🟩 HFV Protocol — SeedSaleWithVesting.sol

This smart contract powers the **HFV Protocol Seed Sale**, allowing users to purchase HFV tokens directly with **ETH or USDC** through the official frontend DApp. Purchased tokens are automatically **locked** and **linearly vested over 6 months**, ensuring long-term alignment with the protocol.


## 🔐 Features

- Accepts payments in **ETH** and **USDC**
- Enforces:
  - ✅ Fixed token price: **$0.99 / HFV**
  - ✅ Minimum purchase: **$250**
  - ✅ Maximum per wallet: **$50,000**
- Tracks total HFV sold (max **2.1M HFV** cap = 3% of total supply)
- Automatically starts a **6-month vesting schedule per buyer**
- Buyers can **claim vested tokens** over time using the DApp or CLI


## 💼 Parameters

| Variable | Value |
|----------------------|----------------------------------|
| `HFV_PRICE` | `$0.99` (in 18 decimals) |
| `HFV_CAP` | `2,100,000 HFV` (3% of supply) |
| `VESTING_DURATION` | `180 days` (linear vesting) |
| `MIN_ETH_PURCHASE` | `~250 USD worth` |
| `MAX_ETH_PURCHASE` | `~50,000 USD worth` |

---

## ⚙️ Functions

### 📥 Buying
- `buyWithETH()` — accepts ETH, calculates HFV, starts vesting  
- `buyWithUSDC(uint256 amount)` — accepts USDC via `transferFrom()`

### 🔓 Vesting + Claims
- `claim()` — lets user withdraw unlocked HFV  
- `vestings(address)` — view total, claimed, and start timestamp

### 🛠 Admin
- `setFundsReceiver(address)` — update ETH/USDC receiver wallet  
- `withdrawUnsold()` — withdraw unsold HFV tokens (after sale)

---

## 🧪 Usage Example

```solidity
// Buy with ETH
contract.buyWithETH({ value: ethers.utils.parseEther(\"1.5\") })

// Claim vested tokens
contract.claim()



🔐 Security Notes

Tokens are not sent immediately — vesting is enforced on-chain

Admin cannot alter allocations once buyers purchase

Cap, price, and vesting terms are locked in contract logic




🧠 Built For

Long-term HFV community believers

Launching Uniswap liquidity in a decentralized, trustless way

Preventing short-term speculation via fair vesting