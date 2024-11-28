;; title: cross-chain-asset-bridge

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-UNAUTHORIZED (err u1))
(define-constant ERR-INSUFFICIENT-BALANCE (err u2))
(define-constant ERR-TRANSFER-FAILED (err u3))
(define-constant ERR-INVALID-CHAIN (err u4))
(define-constant ERR-LIQUIDITY-INSUFFICIENT (err u5))

;; Supported Chains Enum
(define-constant CHAIN-BITCOIN u1)
(define-constant CHAIN-ETHEREUM u2)
(define-constant CHAIN-STACKS u3)

;; Bridge Transaction States
(define-constant TX-PENDING u0)
(define-constant TX-CONFIRMED u1)
(define-constant TX-COMPLETED u2)

;; Cross-Chain Asset Mapping
(define-map CrossChainAssets
  {
    asset-id: (buff 32),
    source-chain: uint,
    destination-chain: uint
  }
  {
    amount: uint,
    sender: principal,
    receiver: principal,
    status: uint,
    timestamp: uint
  }
)

;; Supported Assets Registry
(define-map SupportedAssets
  (buff 32)  ;; Asset Identifier
  {
    name: (string-ascii 50),
    decimals: uint,
    is-enabled: bool
  }
)

;; Bridge Liquidity Pool
(define-map BridgeLiquidityPool
  (buff 32)  ;; Asset Identifier 
  {
    total-liquidity: uint,
    available-liquidity: uint
  }
)

;; Register New Supported Asset
(define-public (register-asset
  (asset-id (buff 32))
  (name (string-ascii 50))
  (decimals uint)
)
  (begin
    ;; Only contract owner can register assets
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-UNAUTHORIZED)
    
    (map-set SupportedAssets 
      asset-id 
      {
        name: name,
        decimals: decimals,
        is-enabled: true
      }
    )
    
    (ok true)
  )
)


;; Initiate Cross-Chain Transfer
(define-public (initiate-transfer
  (asset-id (buff 32))
  (amount uint)
  (destination-chain uint)
  (receiver principal)
)
  (let 
    (
      ;; Validate asset support and retrieve asset info
      (asset-info 
        (unwrap! 
          (map-get? SupportedAssets asset-id) 
          ERR-INVALID-CHAIN ;; Error if asset is not supported
        )
      )
    )
    
    ;; Validate asset is enabled and destination chain is supported
    (asserts! (get is-enabled asset-info) ERR-INVALID-CHAIN)  ;; New validation for asset enabled
    (asserts! 
      (or 
        (is-eq destination-chain CHAIN-BITCOIN)     ;; New validation for supported destination chains
        (is-eq destination-chain CHAIN-ETHEREUM)
        (is-eq destination-chain CHAIN-STACKS)
      ) 
      ERR-INVALID-CHAIN
    )

    ;; Check liquidity and balance (placeholder for actual balance check)
    (asserts! (>= amount u0) ERR-INSUFFICIENT-BALANCE) ;; New balance check (this is a placeholder)

    ;; Record cross-chain transfer in CrossChainAssets map
    (map-set CrossChainAssets 
      {
        asset-id: asset-id,
        source-chain: CHAIN-STACKS,  ;; New source chain constant
        destination-chain: destination-chain
      }
      {
        amount: amount,
        sender: tx-sender,
        receiver: receiver,
        status: TX-PENDING,           ;; New status constant
        timestamp: stacks-block-height,       ;; Using block-height for timestamp
      }
    )

    ;; Return success with transfer details
    (ok {
      status: "Transfer initiated", 
      asset: asset-id, 
      amount: amount, 
      destination: destination-chain, 
      receiver: receiver
    })
  )
)


;; Deposit Liquidity
(define-public (deposit-liquidity
  (asset-id (buff 32))
  (amount uint)
)
  (begin
    ;; Only contract owner can deposit liquidity
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-UNAUTHORIZED)

    ;; Update liquidity pool
    (let ((pool (unwrap! (map-get? BridgeLiquidityPool asset-id) (err u7))))
      (map-set BridgeLiquidityPool asset-id 
        {
          total-liquidity: (+ (get total-liquidity pool) amount),
          available-liquidity: (+ (get available-liquidity pool) amount)
        }
      ))
    (ok true)
  )
)

;; Withdraw Liquidity
(define-public (withdraw-liquidity
  (asset-id (buff 32))
  (amount uint)
)
  (begin
    ;; Only contract owner can withdraw liquidity
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-UNAUTHORIZED)

    ;; Check if enough liquidity is available
    (let ((pool (unwrap! (map-get? BridgeLiquidityPool asset-id) (err u7))))
      (asserts! (>= (get available-liquidity pool) amount) ERR-LIQUIDITY-INSUFFICIENT)
      
      ;; Update liquidity pool
      (map-set BridgeLiquidityPool asset-id 
        {
          total-liquidity: (- (get total-liquidity pool) amount),
          available-liquidity: (- (get available-liquidity pool) amount)
        }
      ))
    (ok true)
  )
)

