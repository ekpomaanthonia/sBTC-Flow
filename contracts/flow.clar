;; sBTC-Flow: A Stacks smart contract for managing sBTC integrations
;; Author: Claude
;; Purpose: Simplify working with sBTC in the Stacks ecosystem

;; Define constants and error codes
(define-constant ERR-NOT-AUTHORIZED (err u401))
(define-constant ERR-INVALID-AMOUNT (err u402))
(define-constant ERR-INSUFFICIENT-BALANCE (err u403))
(define-constant ERR-PENDING-REQUEST (err u404))
(define-constant ERR-NO-PENDING-REQUEST (err u405))
(define-constant ERR-DEPOSIT-FAILED (err u406))
(define-constant ERR-WITHDRAW-FAILED (err u407))
(define-constant ERR-INVALID-BTC-ADDRESS (err u408))

;; Define data maps for tracking balances, deposits, withdrawals, and user data
(define-map user-balances 
  { user: principal } 
  { sbtc-balance: uint }
)

(define-map deposit-requests
  { user: principal, request-id: (buff 32) }
  { 
    amount: uint,
    btc-address: (buff 34),
    status: (string-ascii 20),
    initiated-at: uint
  }
)

(define-map withdraw-requests
  { user: principal, request-id: (buff 32) }
  { 
    amount: uint,
    btc-address: (buff 34),
    status: (string-ascii 20),
    initiated-at: uint
  }
)

(define-map user-profiles
  { user: principal }
  {
    btc-addresses: (list 10 (buff 34)),
    total-deposited: uint,
    total-withdrawn: uint,
    last-activity: uint
  }
)

;; Define variables for contract management
(define-data-var contract-owner principal tx-sender)
(define-data-var sbtc-token-contract principal 'SP000000000000000000002Q6VF78.sbtc)
(define-data-var fee-percentage uint u1) ;; 0.1% represented as basis points (1 = 0.1%)
(define-data-var min-deposit uint u1000000) ;; Minimum deposit in sats (0.01 BTC)
(define-data-var contract-active bool true)
(define-data-var nonce uint u0)

;; Private validation function for Bitcoin addresses
(define-private (is-valid-btc-address (address (buff 34)))
  (let 
    (
      ;; Basic validation checks
      ;; 1. Check address length (34 or 33 bytes)
      ;; 2. Check first byte for address type (1 for legacy, 3 for P2SH, bc1 for bech32)
      (first-byte (unwrap-panic (element-at address u0)))
    )
    (and 
      (or 
        (is-eq first-byte 0x31)   ;; '1' - Legacy P2PKH address
        (is-eq first-byte 0x33)   ;; '3' - P2SH address
        (is-eq first-byte 0x62)   ;; 'b' - bech32 address start
        (is-eq first-byte 0x6d)   ;; 'm' or 'n' - testnet addresses
        (is-eq first-byte 0x6e)
      )
      (>= (len address) u26)      ;; Minimum reasonable address length
      (<= (len address) u34)      ;; Maximum address length
    )
  )
)

;; Read-only functions (previous read-only functions remain the same)
;; ... (keep all previous read-only functions)

;; Utility function to generate unique request ID
(define-private (generate-request-id)
  (let 
    (
      (current-nonce (var-get nonce))
      (new-nonce (+ current-nonce u1))
    )
    (var-set nonce new-nonce)
    ;; Convert current nonce to a 32-byte buffer using block-height and nonce
    (sha256 (concat 
      (unwrap-panic (to-consensus-buff? block-height)) 
      (unwrap-panic (to-consensus-buff? current-nonce))
    ))
  )
)

;; Public functions

;; Initiate a deposit of sBTC
(define-public (initiate-deposit (amount uint) (btc-address (buff 34)))
  (let
    (
      (user tx-sender)
      (request-id (generate-request-id))
      (current-time block-height)
    )
    ;; Validate inputs
    (asserts! (var-get contract-active) ERR-NOT-AUTHORIZED)
    (asserts! (>= amount (var-get min-deposit)) ERR-INVALID-AMOUNT)
    (asserts! (is-valid-btc-address btc-address) ERR-INVALID-BTC-ADDRESS)
    
    ;; Validate that the Bitcoin address hasn't been used too many times
    (asserts! 
      (< 
        (len 
          (match (map-get? user-profiles { user: user })
            profile (get btc-addresses profile)
            (list)
          )
        ) 
        u10
      ) 
      ERR-NOT-AUTHORIZED
    )
    
    ;; Create deposit request
    (map-set deposit-requests
      { user: user, request-id: request-id }
      {
        amount: amount,
        btc-address: btc-address,
        status: "pending",
        initiated-at: current-time
      }
    )
    
    ;; Update user profile
    (match (map-get? user-profiles { user: user })
      profile
      (map-set user-profiles
        { user: user }
        {
          btc-addresses: (unwrap! 
            (as-max-len? 
              (if (is-none (index-of (get btc-addresses profile) btc-address))
                (append (get btc-addresses profile) btc-address)
                (get btc-addresses profile)
              ) 
              u10
            ) 
            ERR-NOT-AUTHORIZED
          ),
          total-deposited: (+ (get total-deposited profile) amount),
          total-withdrawn: (get total-withdrawn profile),
          last-activity: current-time
        }
      )
      (map-set user-profiles
        { user: user }
        {
          btc-addresses: (list btc-address),
          total-deposited: amount,
          total-withdrawn: u0,
          last-activity: current-time
        }
      )
    )
    
    (ok request-id)
  )
)

