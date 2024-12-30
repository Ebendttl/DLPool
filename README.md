# Decentralized Lending Pool Smart Contract (DLPool)

A secure and flexible lending protocol built on the Stacks blockchain that enables decentralized lending with collateral protection mechanisms.

## Overview

The Decentralized Lending Pool Contract provides a trustless platform for lending and borrowing digital assets with built-in protection features. It implements a unique liquidation protection mechanism that shields borrowers during market volatility while maintaining the security of lenders' funds.

## Key Features

### Core Lending Functions
- **Liquidity Provision**: Lenders can provide STX tokens to earn interest
- **Collateralized Borrowing**: 150% collateralization ratio required
- **Interest Generation**: 10% APR on borrowed amounts
- **Automated Repayment**: Built-in interest calculation and repayment handling

### Protection Mechanisms
- **Liquidation Protection**: Time-limited shield against forced liquidations
- **Emergency Refund**: Access to 75% of excess collateral during protection period
- **Protection Pool**: Dedicated safety pool funded by protection fees
- **Interest Waiver**: No interest charges when protection is activated

## Technical Specifications

### Constants
```clarity
COLLATERAL-RATIO: u150 (150%)
INTEREST-RATE: u10 (10% APR)
PROTECTION-FEE: u2 (2%)
PROTECTION-PERIOD: u100 blocks
```

### Error Codes
- `ERR-INSUFFICIENT-COLLATERAL (u1)`: Collateral requirement not met
- `ERR-INSUFFICIENT-LIQUIDITY (u2)`: Requested amount exceeds available liquidity
- `ERR-NO-ACTIVE-LOAN (u3)`: No active loan found for the caller
- `ERR-NO-PROTECTION-ACTIVE (u4)`: Protection features not activated
- `ERR-PROTECTION-ALREADY-ACTIVE (u5)`: Protection already active on loan

## Usage Guide

### For Lenders

1. **Providing Liquidity**
```clarity
(contract-call? .lending-pool provide-liquidity amount)
```
- Amount in STX tokens
- Earns interest from borrowers
- Liquidity can be withdrawn when not utilized

### For Borrowers

1. **Taking a Loan**
```clarity
(contract-call? .lending-pool borrow amount)
```
- Requires 150% collateral in STX
- Collateral locked until repayment
- Interest starts accruing immediately

2. **Activating Protection**
```clarity
(contract-call? .lending-pool activate-protection)
```
- Costs 2% of loan amount
- Provides 100 blocks of protection
- Enables emergency refund feature

3. **Emergency Refund**
```clarity
(contract-call? .lending-pool emergency-refund)
```
- Available during protection period
- Returns 75% of excess collateral
- Maintains minimum required collateral

4. **Loan Repayment**
```clarity
(contract-call? .lending-pool repay)
```
- Repays principal and interest
- Returns full collateral
- No interest if protection was used

## Security Considerations

1. **Collateral Management**
   - Always maintains minimum required collateral
   - Protected withdrawal mechanisms
   - Secure fund storage

2. **Access Control**
   - Function-level authorization checks
   - Protected administrative functions
   - Borrower-specific loan management

3. **Protection Mechanism**
   - Time-locked protection periods
   - Fee-based activation
   - Controlled emergency refunds

## Implementation Notes

### Data Structures

1. **Liquidity Providers Map**
```clarity
(define-map liquidity-providers
  { provider: principal }
  { amount: uint, last-deposit: uint }
)
```

2. **Loans Map**
```clarity
(define-map loans
  { borrower: principal }
  {
    amount: uint,
    collateral: uint,
    start-block: uint,
    interest-due: uint,
    protection-until: uint,
    protection-active: bool
  }
)
```

3. **Protection Pool Map**
```clarity
(define-map protection-pool
  { id: uint }
  { balance: uint }
)
```

## Development and Testing

### Prerequisites
- Clarinet
- Node.js
- Stacks CLI

### Local Testing
1. Clone the repository
2. Install dependencies
3. Run Clarinet console:
```bash
clarinet console
```

### Test Commands
```clarity
;; Test liquidity provision
(contract-call? .lending-pool provide-liquidity u1000)

;; Test borrowing
(contract-call? .lending-pool borrow u500)

;; Test protection activation
(contract-call? .lending-pool activate-protection)
```

## Contributing

Contributions are welcome! Please follow these steps:
1. Fork the repository
2. Create a feature branch
3. Commit changes
4. Submit pull request

## License

This project is licensed under the MIT License.

## Disclaimer

This smart contract is provided as-is. Users should conduct their own security audit before deployment. The developers are not responsible for any losses incurred through the use of this contract.
