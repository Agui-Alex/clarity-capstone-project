;; sip009-nft with a mint function
(impl-trait .sip009-trait.sip009-nft-trait)

(define-constant contract-owner tx-sender)

(define-constant err-owner-only (err u100))
(define-constant err-token-id-failure (err u101))
(define-constant err-not-token-owner (err u102))

(define-non-fungible-token AnG_Project uint)
(define-data-var token-id-nonce uint u0)

(define-read-only (get-last-token-id)
    (ok (var-get token-id-nonce))
)

(define-read-only (get-token-uri (token-id uint))
 (ok none)
)

(define-read-only (get-owner (token-id uint))
 (ok (some tx-sender))
 )

(define-public (transfer (token-id uint) (sender principal) (recipient principal))
 (begin 
    (asserts! (is-eq tx-sender sender) err-not-token-owner)
    (nft-transfer? AnG_Project token-id sender recipient))
)

(define-public (mint (recipient principal))
	(let ((token-id (+ (var-get token-id-nonce) u1)))
		(asserts! (is-eq tx-sender contract-owner) err-owner-only)
		(try! (nft-mint? AnG_Project token-id recipient))
		(asserts! (var-set token-id-nonce token-id) err-token-id-failure)
		(ok token-id)
	)
)
