;; title: cross-chain-asset-bridge

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-UNAUTHORIZED (err u1))
(define-constant ERR-INSUFFICIENT-BALANCE (err u2))
(define-constant ERR-TRANSFER-FAILED (err u3))
(define-constant ERR-INVALID-CHAIN (err u4))

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

