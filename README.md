# sBTC Flow Smart Contract

## Overview

sBTC Flow is a Stacks smart contract designed to simplify and secure Bitcoin (BTC) integration within the Stacks ecosystem. This contract provides a robust mechanism for managing sBTC deposits and withdrawals with enhanced security features.

## Features

- Secure Bitcoin address validation
- Deposit and withdrawal request management
- User balance tracking
- Multiple Bitcoin address support per user
- Request ID generation and validation
- Configurable minimum deposit amounts
- Contract owner management

## Key Components

### Data Maps
- `user-balances`: Tracks sBTC balances for users
- `deposit-requests`: Manages deposit request details
- `withdraw-requests`: Tracks withdrawal request information
- `user-profiles`: Stores user-specific metadata

### Main Functions

#### Deposit Flow
- `initiate-deposit`: Creates a new deposit request
  - Validates Bitcoin address
  - Checks minimum deposit amount
  - Generates unique request ID
- `complete-deposit`: Finalizes deposit after confirmation

### Security Measures
- Input validation for Bitcoin addresses
- Request ID validation
- User and contract owner authorization checks
- Limit on number of Bitcoin addresses per user

## Error Handling

The contract includes comprehensive error codes for various scenarios:
- Authorization errors
- Invalid amount errors
- Insufficient balance errors
- Deposit and withdrawal failures
- Bitcoin address validation errors

## Configuration

Configurable parameters include:
- Minimum deposit amount
- Contract activation status
- Fee percentage

## Requirements

- Stacks blockchain
- Compatible sBTC token contract

## Installation

1. Deploy the contract to the Stacks blockchain
2. Set contract owner
3. Configure initial parameters

## Contributing

Contributions are welcome! Please submit pull requests with detailed descriptions of changes.

