# EntropyEqualityComparison

FHE equality comparison using EntropyOracle

## 🚀 Quick Start

1. **Clone this repository:**
   ```bash
   git clone https://github.com/zacnider/fhevm-example-basic-equalitycomparison.git
   cd fhevm-example-basic-equalitycomparison
   ```

2. **Install dependencies:**
   ```bash
   npm install --legacy-peer-deps
   ```

3. **Setup environment:**
   ```bash
   npm run setup
   ```
   Then edit `.env` file with your credentials:
   - `SEPOLIA_RPC_URL` - Your Sepolia RPC endpoint
   - `PRIVATE_KEY` - Your wallet private key (for deployment)
   - `ETHERSCAN_API_KEY` - Your Etherscan API key (for verification)

4. **Compile contracts:**
   ```bash
   npm run compile
   ```

5. **Run tests:**
   ```bash
   npm test
   ```

6. **Deploy to Sepolia:**
   ```bash
   npm run deploy:sepolia
   ```

7. **Verify contract (after deployment):**
   ```bash
   npm run verify <CONTRACT_ADDRESS>
   ```

**Alternative:** Use the [Examples page](https://entrofhe.vercel.app/examples) for browser-based deployment and verification.

---


## 🚀 Standard workflow
- Install (first run): `npm install --legacy-peer-deps`
- Compile: `npx hardhat compile`
- Test (local FHE + local oracle/chaos engine auto-deployed): `npx hardhat test`
- Deploy (frontend Deploy button): constructor arg is fixed to EntropyOracle `0x75b923d7940E1BD6689EbFdbBDCD74C1f6695361`
- Verify: `npx hardhat verify --network sepolia <contractAddress> 0x75b923d7940E1BD6689EbFdbBDCD74C1f6695361`

## 📋 Overview

This example demonstrates **basic** concepts in FHEVM with **EntropyOracle integration**:
- Integrating with EntropyOracle
- Using encrypted entropy in equality comparisons
- Entropy-enhanced comparison operations
- Combining entropy with encrypted values for comparisons

## 🎯 What This Example Teaches

This tutorial will teach you:

1. **How to compare encrypted values** for equality using `FHE.eq()`
2. **How to work with `ebool`** (encrypted boolean) results
3. **How to enhance comparisons** with entropy from EntropyOracle
4. **How to mix values with entropy** before comparison
5. **The importance of `FHE.allowThis()`** for encrypted values and results
6. **Understanding encrypted boolean operations**

## 💡 Why This Matters

Equality comparisons are essential for conditional logic in smart contracts. With EntropyOracle, you can:
- **Add randomness** to comparison results without revealing values
- **Enhance security** by mixing entropy with values before comparison
- **Create unpredictable patterns** in encrypted conditionals
- **Learn the foundation** for more complex FHE conditional logic

## 🔍 How It Works

### Contract Structure

The contract has four main components:

1. **Initialization**: Sets up two encrypted values for comparison
2. **Entropy Request**: Requests randomness from EntropyOracle
3. **Basic Comparison**: Compares values for equality (returns `ebool`)
4. **Entropy-Enhanced Comparison**: Mixes values with entropy before comparison

### Step-by-Step Code Explanation

#### 1. Constructor

```solidity
constructor(address _entropyOracle) {
    require(_entropyOracle != address(0), "Invalid oracle address");
    entropyOracle = IEntropyOracle(_entropyOracle);
}
```

**What it does:**
- Takes EntropyOracle address as parameter
- Validates the address is not zero
- Stores the oracle interface

**Why it matters:**
- Must use the correct oracle address: `0x75b923d7940E1BD6689EbFdbBDCD74C1f6695361`

#### 2. Initialize Function

```solidity
function initialize(
    externalEuint64 encryptedValue1,
    externalEuint64 encryptedValue2,
    bytes calldata inputProof1,
    bytes calldata inputProof2
) external {
    require(!initialized, "Already initialized");
    
    euint64 internalValue1 = FHE.fromExternal(encryptedValue1, inputProof1);
    euint64 internalValue2 = FHE.fromExternal(encryptedValue2, inputProof2);
    
    FHE.allowThis(internalValue1);
    FHE.allowThis(internalValue2);
    
    value1 = internalValue1;
    value2 = internalValue2;
    initialized = true;
}
```

**What it does:**
- Accepts two encrypted values from external source
- Validates both using separate input proofs
- Converts to internal format
- Grants permission to use both values
- Stores them for comparison

**Key concepts:**
- **Two external inputs**: Each requires its own `inputProof`
- **Multiple `FHE.allowThis()` calls**: One for each encrypted value

#### 3. Request Entropy

```solidity
function requestEntropy(bytes32 tag) external payable returns (uint256 requestId) {
    require(initialized, "Not initialized");
    require(msg.value >= entropyOracle.getFee(), "Insufficient fee");
    
    requestId = entropyOracle.requestEntropy{value: msg.value}(tag);
    entropyRequests[requestId] = true;
    
    return requestId;
}
```

**What it does:**
- Checks contract is initialized
- Validates fee payment
- Requests entropy from EntropyOracle
- Stores request ID
- Returns request ID

#### 4. Compare Function

```solidity
function compare() external returns (ebool result) {
    require(initialized, "Not initialized");
    result = FHE.eq(value1, value2);
    emit ComparisonPerformed(result);
    return result;
}
```

**What it does:**
- Compares two encrypted values for equality
- Returns encrypted boolean (`ebool`)
- Result is encrypted (decrypt off-chain to see true/false)

**Key concepts:**
- `FHE.eq()`: Equality comparison on encrypted values
- `ebool`: Encrypted boolean type
- Result is encrypted, not plain boolean

**Why encrypted result:**
- Maintains privacy - even the comparison result is encrypted
- Can be decrypted off-chain by authorized users

#### 5. Compare with Entropy

```solidity
function compareWithEntropy(uint256 requestId) external returns (ebool result) {
    require(entropyOracle.isRequestFulfilled(requestId), "Entropy not ready");
    
    euint64 entropy = entropyOracle.getEncryptedEntropy(requestId);
    FHE.allowThis(entropy);  // CRITICAL!
    
    euint64 mixedValue1 = FHE.xor(value1, entropy);
    FHE.allowThis(mixedValue1);
    euint64 mixedValue2 = FHE.xor(value2, entropy);
    FHE.allowThis(mixedValue2);
    
    result = FHE.eq(mixedValue1, mixedValue2);
    
    return result;
}
```

**What it does:**
- Validates request ID and fulfillment status
- Gets encrypted entropy from oracle
- **Grants permission** to use entropy (CRITICAL!)
- Mixes both values with entropy using XOR
- Compares mixed values for equality
- Returns encrypted boolean result

**Key concepts:**
- **XOR mixing**: Both values mixed with same entropy
- **Comparison after mixing**: Compares entropy-mixed values
- **Multiple `FHE.allowThis()` calls**: Required for entropy and mixed values

**Why mix before compare:**
- XOR adds randomness to values before comparison
- Same entropy used for both values maintains equality relationship
- Result: Entropy-enhanced comparison

**Common mistake:**
- Forgetting `FHE.allowThis(entropy)` causes `SenderNotAllowed()` error

## 🧪 Step-by-Step Testing

### Prerequisites

1. **Install dependencies:**
   ```bash
   npm install --legacy-peer-deps
   ```

2. **Compile contracts:**
   ```bash
   npx hardhat compile
   ```

### Running Tests

```bash
npx hardhat test
```

### What Happens in Tests

1. **Fixture Setup** (`deployContractFixture`):
   - Deploys FHEChaosEngine, EntropyOracle, and EntropyEqualityComparison
   - Returns all contract instances

2. **Test: Initialization**
   ```typescript
   it("Should initialize with two encrypted values", async function () {
     const input1 = hre.fhevm.createEncryptedInput(contractAddress, owner.address);
     input1.add64(5);
     const encryptedInput1 = await input1.encrypt();
     
     const input2 = hre.fhevm.createEncryptedInput(contractAddress, owner.address);
     input2.add64(5);  // Same value for equality test
     const encryptedInput2 = await input2.encrypt();
     
     await contract.initialize(
       encryptedInput1.handles[0],
       encryptedInput2.handles[0],
       encryptedInput1.inputProof,
       encryptedInput2.inputProof
     );
   });
   ```
   - Creates two encrypted inputs (can be same or different values)
   - Encrypts both using FHEVM SDK
   - Calls `initialize()` with both handles and proofs

3. **Test: Basic Comparison**
   ```typescript
   it("Should perform equality comparison", async function () {
     // ... initialization code ...
     const result = await contract.compare();
     expect(result).to.not.be.undefined;
   });
   ```
   - Performs equality comparison
   - Result is `ebool` (encrypted boolean)
   - Decrypt off-chain to see actual true/false

4. **Test: Entropy Request**
   ```typescript
   it("Should request entropy", async function () {
     const tag = hre.ethers.id("test-comparison");
     const fee = await oracle.getFee();
     await expect(
       contract.requestEntropy(tag, { value: fee })
     ).to.emit(contract, "EntropyRequested");
   });
   ```
   - Requests entropy with unique tag
   - Pays required fee
   - Verifies request event is emitted

### Expected Test Output

```
  EntropyEqualityComparison
    Deployment
      ✓ Should deploy successfully
      ✓ Should not be initialized by default
      ✓ Should have EntropyOracle address set
    Initialization
      ✓ Should initialize with two encrypted values
      ✓ Should not allow double initialization
    Basic Comparison
      ✓ Should perform equality comparison
      ✓ Should return encrypted boolean result
      ✓ Should not allow comparison before initialization
    Entropy-based Comparison
      ✓ Should request entropy
      ✓ Should perform entropy-enhanced comparison

  10 passing
```

**Note:** Encrypted values and boolean results appear as handles in test output. Decrypt off-chain to see actual values.

## 🚀 Step-by-Step Deployment

### Option 1: Frontend (Recommended)

1. Navigate to [Examples page](https://entrofhe.vercel.app/examples)
2. Find "EntropyEqualityComparison" in Tutorial Examples
3. Click **"Deploy"** button
4. Approve transaction in wallet
5. Wait for deployment confirmation
6. Copy deployed contract address

### Option 2: CLI

1. **Create deploy script** (`scripts/deploy.ts`):
   ```typescript
   import hre from "hardhat";

   async function main() {
     const ENTROPY_ORACLE_ADDRESS = "0x75b923d7940E1BD6689EbFdbBDCD74C1f6695361";
     
     const ContractFactory = await hre.ethers.getContractFactory("EntropyEqualityComparison");
     const contract = await ContractFactory.deploy(ENTROPY_ORACLE_ADDRESS);
     await contract.waitForDeployment();
     
     const address = await contract.getAddress();
     console.log("EntropyEqualityComparison deployed to:", address);
   }

   main().catch((error) => {
     console.error(error);
     process.exitCode = 1;
   });
   ```

2. **Deploy:**
   ```bash
   npx hardhat run scripts/deploy.ts --network sepolia
   ```

## ✅ Step-by-Step Verification

### Option 1: Frontend

1. After deployment, click **"Verify"** button on Examples page
2. Wait for verification confirmation
3. View verified contract on Etherscan

### Option 2: CLI

```bash
npx hardhat verify --network sepolia <CONTRACT_ADDRESS> 0x75b923d7940E1BD6689EbFdbBDCD74C1f6695361
```

**Important:** Constructor argument must be the EntropyOracle address: `0x75b923d7940E1BD6689EbFdbBDCD74C1f6695361`

## 📊 Expected Outputs

### After Initialization

- `isInitialized()` returns `true`
- Two encrypted values stored (value1 and value2)
- `ValuesInitialized` event emitted

### After Basic Comparison

- `compare()` returns encrypted boolean (`ebool`)
- Result is encrypted (decrypt off-chain to see true/false)
- `ComparisonPerformed` event emitted with encrypted result

### After Entropy-Enhanced Comparison

- `compareWithEntropy()` returns entropy-enhanced encrypted boolean
- Values are mixed with entropy before comparison
- Result is unpredictable due to entropy mixing
- All operations performed on encrypted data

## ⚠️ Common Errors & Solutions

### Error: `SenderNotAllowed()`

**Cause:** Missing `FHE.allowThis()` call on encrypted value.

**Example:**
```solidity
euint64 entropy = entropyOracle.getEncryptedEntropy(requestId);
// Missing: FHE.allowThis(entropy);
euint64 mixed = FHE.xor(value1, entropy); // ❌ Error!
```

**Solution:**
```solidity
euint64 entropy = entropyOracle.getEncryptedEntropy(requestId);
FHE.allowThis(entropy); // ✅ Required!
euint64 mixed = FHE.xor(value1, entropy);
FHE.allowThis(mixed);
```

**Prevention:** Always call `FHE.allowThis()` on all encrypted values before using them.

---

### Error: `Incorrect number of arguments`

**Cause:** Wrong number of input proofs passed to `initialize()`.

**Solution:** Each `externalEuint64` parameter requires its own `inputProof`. For two inputs, pass two proofs.

---

### Error: `Entropy not ready`

**Cause:** Calling `compareWithEntropy()` before entropy is fulfilled.

**Solution:** Always check `isRequestFulfilled()` before using entropy.

---

### Error: `Invalid oracle address`

**Cause:** Wrong or zero address passed to constructor.

**Solution:** Always use the fixed EntropyOracle address: `0x75b923d7940E1BD6689EbFdbBDCD74C1f6695361`

---

### Error: `Already initialized`

**Cause:** Trying to initialize contract twice.

**Solution:** Initialize only once. If you need to reset, deploy a new contract.

---

### Error: `Insufficient fee`

**Cause:** Not sending enough ETH when requesting entropy.

**Solution:** Always send exactly 0.00001 ETH:
```typescript
const fee = await contract.entropyOracle.getFee();
await contract.requestEntropy(tag, { value: fee });
```

---

### Error: Verification failed - Constructor arguments mismatch

**Cause:** Wrong constructor argument used during verification.

**Solution:** Always use the EntropyOracle address:
```bash
npx hardhat verify --network sepolia <CONTRACT_ADDRESS> 0x75b923d7940E1BD6689EbFdbBDCD74C1f6695361
```

## 🔗 Related Examples

- [EntropyCounter](../basic-simplecounter/) - Entropy-based counter
- [EntropyArithmetic](../basic-arithmetic/) - Entropy-based arithmetic
- [EntropyEncryption](../encryption-encryptsingle/) - Encrypting values with entropy
- [Category: basic](../)

## 📚 Additional Resources

- [Full Tutorial Track Documentation](../../../frontend/src/pages/Docs.tsx) - Complete educational guide
- [Zama FHEVM Documentation](https://docs.zama.org/) - Official FHEVM docs
- [GitHub Repository](https://github.com/zacnider/fhevm-example-basic-equalitycomparison) - Source code

## 📝 License

BSD-3-Clause-Clear
