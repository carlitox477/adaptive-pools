#!/bin/bash

# Install Foundry dependencies
echo "Installing Foundry dependencies..."
forge install
wait

# Search and replace pragma solidity version in Solidity files within lib/v4-core and lib/v4-periphery
echo "Updating pragma solidity version..."
find lib/v4-core lib/v4-periphery -type f -name "*.sol" ! -name "*.t.sol" -exec sed -i '' 's/pragma solidity \^0\.8\.24;/pragma solidity ^0.8.4;/g' {} +
wait

# Run tests using forge test with the specified solc binary
echo "Running tests..."
forge test --use bin/solc
wait