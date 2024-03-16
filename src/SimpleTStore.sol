// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.20;

/// @title SimpleTStore
/// @dev This contract demonstrates the use of EVM's `tstore` and `tload` instructions for direct storage access.

contract SimpleTStore {
    
    /// @notice Stores a value at a specified storage slot.
    /// @dev Directly writes a value to storage using inline assembly and the `tstore` opcode.
    /// @param key The storage slot to write to.
    /// @param value The value to store at the specified slot.
    function tstore(uint key, uint value) external {
        assembly {
            tstore(key, value)
        }
    }

    /// @notice Loads a value from a specified storage slot.
    /// @dev Reads a value from storage using inline assembly and the `tload` opcode.
    /// @param key The storage slot to read from.
    /// @return value The value stored at the specified slot.
    function tload(uint key) external view returns (uint value) {
        assembly {
            value := tload(key)
        }
    }
}
