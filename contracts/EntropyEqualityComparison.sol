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
