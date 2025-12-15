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

## 📋 Overview

@title EntropyEqualityComparison
@notice FHE equality comparison using EntropyOracle
@dev Example demonstrating EntropyOracle integration: using entropy in equality comparisons
This example shows:
- How to integrate with EntropyOracle
- Using entropy to enhance comparison operations
- Entropy-based equality checks
- Combining entropy with encrypted values for comparisons

@notice Constructor - sets EntropyOracle address
@param _entropyOracle Address of EntropyOracle contract

@notice Initialize two encrypted values
@param encryptedValue1 First encrypted value
@param encryptedValue2 Second encrypted value
@param inputProof1 Input proof for first encrypted value
@param inputProof2 Input proof for second encrypted value

@notice Request entropy for comparison operations
@param tag Unique tag for this request
@return requestId Request ID from EntropyOracle
@dev Requires 0.00001 ETH fee

@notice Compare two encrypted values for equality
@return result Encrypted boolean (ebool): true if value1 == value2, false otherwise

@notice Compare values with entropy enhancement
@param requestId Request ID from requestEntropy()
@return result Encrypted boolean enhanced with entropy

@notice Check if values are initialized

@notice Get EntropyOracle address



## 🔐 Zama FHEVM Usage

This example demonstrates the following **Zama FHEVM** features:

### Zama FHEVM Features Used

- **ZamaEthereumConfig**: Inherits from Zama's network configuration
  ```solidity
  contract MyContract is ZamaEthereumConfig {
      // Inherits network-specific FHEVM configuration
  }
  ```

- **FHE Operations**: Uses Zama's FHE library for encrypted operations
  - `FHE.add()` - Zama FHEVM operation
  - `FHE.sub()` - Zama FHEVM operation
  - `FHE.mul()` - Zama FHEVM operation
  - `FHE.eq()` - Zama FHEVM operation
  - `FHE.xor()` - Zama FHEVM operation

- **Encrypted Types**: Uses Zama's encrypted integer types
  - `euint64` - 64-bit encrypted unsigned integer
  - `externalEuint64` - External encrypted value from user

- **Access Control**: Uses Zama's permission system
  - `FHE.allowThis()` - Allow contract to use encrypted values
  - `FHE.allow()` - Allow specific user to decrypt
  - `FHE.allowTransient()` - Temporary permission for single operation
  - `FHE.fromExternal()` - Convert external encrypted values to internal

### Zama FHEVM Imports

```solidity
// Zama FHEVM Core Library - FHE operations and encrypted types
import {FHE, euint64, externalEuint64} from "@fhevm/solidity/lib/FHE.sol";

// Zama Network Configuration - Provides network-specific settings
import {ZamaEthereumConfig} from "@fhevm/solidity/config/ZamaConfig.sol";
```

### Zama FHEVM Code Example

```solidity
// Using Zama FHEVM's encrypted integer type
euint64 private encryptedValue;

// Converting external encrypted value to internal (Zama FHEVM)
euint64 internalValue = FHE.fromExternal(encryptedValue, inputProof);
FHE.allowThis(internalValue); // Zama FHEVM permission system

// Performing encrypted operations using Zama FHEVM
euint64 result = FHE.add(encryptedValue, FHE.asEuint64(1));
FHE.allowThis(result);
```

### Zama FHEVM Concepts Demonstrated

1. **Encrypted Arithmetic**: Using Zama FHEVM to encrypted arithmetic
2. **Encrypted Comparison**: Using Zama FHEVM to encrypted comparison
3. **External Encryption**: Using Zama FHEVM to external encryption
4. **Permission Management**: Using Zama FHEVM to permission management
5. **Entropy Integration**: Using Zama FHEVM to entropy integration

### Learn More About Zama FHEVM

- 📚 [Zama FHEVM Documentation](https://docs.zama.org/protocol)
- 🎓 [Zama Developer Hub](https://www.zama.org/developer-hub)
- 💻 [Zama FHEVM GitHub](https://github.com/zama-ai/fhevm)


## 🔍 Contract Code

```solidity
// SPDX-License-Identifier: BSD-3-Clause-Clear
pragma solidity ^0.8.27;

import {FHE, euint64, externalEuint64, ebool} from "@fhevm/solidity/lib/FHE.sol";
import {ZamaEthereumConfig} from "@fhevm/solidity/config/ZamaConfig.sol";
import "./IEntropyOracle.sol";

/**
 * @title EntropyEqualityComparison
 * @notice FHE equality comparison using EntropyOracle
 * @dev Example demonstrating EntropyOracle integration: using entropy in equality comparisons
 * 
 * This example shows:
 * - How to integrate with EntropyOracle
 * - Using entropy to enhance comparison operations
 * - Entropy-based equality checks
 * - Combining entropy with encrypted values for comparisons
 */
contract EntropyEqualityComparison is ZamaEthereumConfig {
    // Entropy Oracle interface
    IEntropyOracle public entropyOracle;
    
    // Encrypted values to compare
    euint64 private value1;
    euint64 private value2;
    
    bool private initialized;
    
    // Track entropy requests
    mapping(uint256 => bool) public entropyRequests;
    
    event ValuesInitialized(address indexed initializer);
    event EntropyRequested(uint256 indexed requestId, address indexed caller);
    event ComparisonPerformed(ebool result);
    event EntropyComparisonPerformed(uint256 indexed requestId, ebool result);
    
    /**
     * @notice Constructor - sets EntropyOracle address
     * @param _entropyOracle Address of EntropyOracle contract
     */
    constructor(address _entropyOracle) {
        require(_entropyOracle != address(0), "Invalid oracle address");
        entropyOracle = IEntropyOracle(_entropyOracle);
    }
    
    /**
     * @notice Initialize two encrypted values
     * @param encryptedValue1 First encrypted value
     * @param encryptedValue2 Second encrypted value
     * @param inputProof1 Input proof for first encrypted value
     * @param inputProof2 Input proof for second encrypted value
     */
    function initialize(
        externalEuint64 encryptedValue1,
        externalEuint64 encryptedValue2,
        bytes calldata inputProof1,
        bytes calldata inputProof2
    ) external {
        require(!initialized, "Already initialized");
        
        // Convert external to internal
        euint64 internalValue1 = FHE.fromExternal(encryptedValue1, inputProof1);
        euint64 internalValue2 = FHE.fromExternal(encryptedValue2, inputProof2);
        
        // Allow contract to use
        FHE.allowThis(internalValue1);
        FHE.allowThis(internalValue2);
        
        value1 = internalValue1;
        value2 = internalValue2;
        initialized = true;
        
        emit ValuesInitialized(msg.sender);
    }
    
    /**
     * @notice Request entropy for comparison operations
     * @param tag Unique tag for this request
     * @return requestId Request ID from EntropyOracle
     * @dev Requires 0.00001 ETH fee
     */
    function requestEntropy(bytes32 tag) external payable returns (uint256 requestId) {
        require(initialized, "Not initialized");
        require(msg.value >= entropyOracle.getFee(), "Insufficient fee");
        
        requestId = entropyOracle.requestEntropy{value: msg.value}(tag);
        entropyRequests[requestId] = true;
        
        emit EntropyRequested(requestId, msg.sender);
        return requestId;
    }
    
    /**
     * @notice Compare two encrypted values for equality
     * @return result Encrypted boolean (ebool): true if value1 == value2, false otherwise
     */
    function compare() external returns (ebool result) {
        require(initialized, "Not initialized");
        result = FHE.eq(value1, value2);
        emit ComparisonPerformed(result);
        return result;
    }
    
    /**
     * @notice Compare values with entropy enhancement
     * @param requestId Request ID from requestEntropy()
     * @return result Encrypted boolean enhanced with entropy
     */
    function compareWithEntropy(uint256 requestId) external returns (ebool result) {
        require(initialized, "Not initialized");
        require(entropyRequests[requestId], "Invalid request ID");
        require(entropyOracle.isRequestFulfilled(requestId), "Entropy not ready");
        
        // Get entropy
        euint64 entropy = entropyOracle.getEncryptedEntropy(requestId);
        FHE.allowThis(entropy);
        
        // Mix values with entropy before comparison
        euint64 mixedValue1 = FHE.xor(value1, entropy);
        FHE.allowThis(mixedValue1);
        euint64 mixedValue2 = FHE.xor(value2, entropy);
        FHE.allowThis(mixedValue2);
        
        // Compare mixed values
        result = FHE.eq(mixedValue1, mixedValue2);
        
        entropyRequests[requestId] = false;
        emit EntropyComparisonPerformed(requestId, result);
        return result;
    }
    
    /**
     * @notice Check if values are initialized
     */
    function isInitialized() external view returns (bool) {
        return initialized;
    }
    
    /**
     * @notice Get EntropyOracle address
     */
    function getEntropyOracle() external view returns (address) {
        return address(entropyOracle);
    }
}

```

## 🧪 Tests

See [test file](./test/EntropyEqualityComparison.test.ts) for comprehensive test coverage.

```bash
npm test
```


## 📚 Category

**basic**



## 🔗 Related Examples

- [All basic examples](https://github.com/zacnider/entrofhe/tree/main/examples)

## 📝 License

BSD-3-Clause-Clear
