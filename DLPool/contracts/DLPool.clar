;; DECENTRALIZED LENDING POOL WITH LIQUIDATION PROTECTION
;; A secure and flexible lending protocol for decentralized lending with collateral protection mechanisms.

(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-INSUFFICIENT-COLLATERAL (err u1))
(define-constant ERR-INSUFFICIENT-LIQUIDITY (err u2))
(define-constant ERR-NO-ACTIVE-LOAN (err u3))
(define-constant ERR-NO-PROTECTION-ACTIVE (err u4))
(define-constant ERR-PROTECTION-ALREADY-ACTIVE (err u5))
(define-constant COLLATERAL-RATIO u150) ;; 150% collateralization required
(define-constant INTEREST-RATE u10) ;; 10% APR
(define-constant PROTECTION-FEE u2) ;; 2% of loan amount
(define-constant PROTECTION-PERIOD u100) ;; 100 blocks of protection

(define-map liquidity-providers
  { provider: principal }
  { amount: uint, last-deposit: uint }
)

(define-map loans
  { borrower: principal }
  {
    amount: uint,
    collateral: uint,
    start-block: uint,
    interest-due: uint,
    protection-until: uint,  ;; field for protection period
    protection-active: bool  ;; field to track protection status
  }
)

(define-map protection-pool
  { id: uint }
  { balance: uint }
)

(define-data-var total-liquidity uint u0)
(define-data-var protection-pool-id uint u1)

;; Existing functions remain the same until borrow...

(define-public (borrow (amount uint))
  (let (
    (required-collateral (/ (* amount COLLATERAL-RATIO) u100))
  )
    (asserts! (<= amount (var-get total-liquidity)) ERR-INSUFFICIENT-LIQUIDITY)
    (try! (stx-transfer? required-collateral tx-sender (as-contract tx-sender)))
    (try! (as-contract (stx-transfer? amount tx-sender tx-sender)))
    
    (map-set loans
      { borrower: tx-sender }
      {
        amount: amount,
        collateral: required-collateral,
        start-block: block-height,
        interest-due: u0,
        protection-until: u0,
        protection-active: false
      }
    )
    (var-set total-liquidity (- (var-get total-liquidity) amount))
    (ok amount)
  )
)

;; Activate liquidation protection
(define-public (activate-protection)
  (let (
    (loan (unwrap! (map-get? loans { borrower: tx-sender }) ERR-NO-ACTIVE-LOAN))
    (protection-fee (/ (* (get amount loan) PROTECTION-FEE) u100))
  )
    (asserts! (not (get protection-active loan)) ERR-PROTECTION-ALREADY-ACTIVE)
    (try! (stx-transfer? protection-fee tx-sender (as-contract tx-sender)))
    
    ;; Add fee to protection pool
    (map-set protection-pool
      { id: (var-get protection-pool-id) }
      { balance: (+ (default-to u0 (get balance (map-get? protection-pool { id: (var-get protection-pool-id) }))) protection-fee) }
    )
    
    ;; Update loan with protection
    (map-set loans
      { borrower: tx-sender }
      (merge loan {
        protection-until: (+ block-height PROTECTION-PERIOD),
        protection-active: true
      })
    )
    (ok true)
  )
)

;; Emergency refund with protection
(define-public (emergency-refund)
  (let (
    (loan (unwrap! (map-get? loans { borrower: tx-sender }) ERR-NO-ACTIVE-LOAN))
  )
    (asserts! (get protection-active loan) ERR-NO-PROTECTION-ACTIVE)
    (asserts! (<= block-height (get protection-until loan)) ERR-NO-PROTECTION-ACTIVE)
    
    ;; Calculate partial collateral return (75% of excess collateral)
    (let (
      (excess-collateral (- (get collateral loan) (get amount loan)))
      (refund-amount (/ (* excess-collateral u75) u100))
    )
      ;; Return partial collateral while maintaining loan security
      (try! (as-contract (stx-transfer? refund-amount tx-sender tx-sender)))
      
      ;; Update loan with reduced collateral
      (map-set loans
        { borrower: tx-sender }
        (merge loan {
          collateral: (- (get collateral loan) refund-amount),
          protection-active: false
        })
      )
      (ok refund-amount)
    )
  )
)

;; Repay function to handle protection status
(define-public (repay)
  (let (
    (loan (unwrap! (map-get? loans { borrower: tx-sender }) ERR-NO-ACTIVE-LOAN))
    (blocks-elapsed (- block-height (get start-block loan)))
    (interest-amount (/ (* (get amount loan) INTEREST-RATE blocks-elapsed) (* u100 u2100)))
    (protection-active (get protection-active loan))
  )
    (if protection-active
      (try! (stx-transfer? (get amount loan) tx-sender (as-contract tx-sender))) ;; No interest if protection was used
      (try! (stx-transfer? (+ (get amount loan) interest-amount) tx-sender (as-contract tx-sender)))
    )
    (try! (as-contract (stx-transfer? (get collateral loan) tx-sender tx-sender)))
    (map-delete loans { borrower: tx-sender })
    (var-set total-liquidity (+ (var-get total-liquidity) (get amount loan)))
    (ok true)
  )
)