(use-trait sip009-nft-trait .sip009-trait.sip009-nft-trait)
(use-trait sip010-ft-trait .sip010-ft-trait.sip10-ft-trait)

(define-constant contract-owner tx-sender)

;;listing errors
(define-constant err-expiry-in-past (err u1000))
(define-constant err-price-zero (err u1001))

;; cancelling and fulfilling errors
(define-constant err-unknown-listing (err u2000))
(define-constant err-unauthorised (err u2001))
(define-constant err-listing-expired (err u2002))
(define-constant err-nft-asset-mismatch (err u2003))
(define-constant err-payment-asset-mismatch (err u2004))
(define-constant err-maker-taker-equal (err u2005))
(define-constant err-unintended-taker (err u2006))
(define-constant err-asset-contract-not-whitelisted (err u2007))
(define-constant err-payment-contract-not-whitelisted (err u2008))

;;data storage
(define-map listings
	uint
	{
		maker: principal,
		taker: (optional principal),
		token-id: uint,
		nft-asset-contract: principal,
		expiry: uint,
		price: uint,
		payment-asset-contract: (optional principal)
	}
)

(define-data-var listing-nonce uint u0)

(define-map whitelisted-asset-contracts principal bool)

(define-read-only (is-whitelisted (asset-contract principal))
	(default-to false (map-get? whitelisted-asset-contracts asset-contract))
)

(define-public (set-whitelisted (asset-contract principal) (whitelisted bool))
	(begin
		(asserts! (is-eq contract-owner tx-sender) err-unauthorised)
		(ok (map-set whitelisted-asset-contracts asset-contract whitelisted))
	)
)

(define-private (transfer-nft (token-contract <sip009-nft-trait>) (token-id uint) (sender principal) (resipient principal)) 
    (contract-call? token-contract transfer token-id sender recipient)
)

(define-private (transfer-ft (token-contract <sip010-ft-trait>) (amount uint) (sender principala) (recipient principal))
    (contract-call? token-contract transfer amount sender recipient none)
)

(define-public (list-asset (nft-asset-contract <sip009-nft-trait>) (nft-asset {taker: (optional principal), token-id: uint, price: uint, payment-asset-contract: (optional principal)}))
    (let ((lsiting-id (var-get listing-nonce)))
        (asserts! (is-whitelisted (contract-of nft-asset-contract)) err-asset-not-whitelisted)
        (asserts! (> (get expiry nft-asset) block-height) err-expiry-in-past)
        (asserts! (> (get price nft-asset) u0) err-price-zero)
        (asserts! (match (get payment-asset-contract nft-asset) payment-asset (is-whitelisted payment-asset) true) err-payment-contract-not-whitelisted)
        (try! (transfer-nft nft-asset-contract (get token-id nft-asset) tx-sender (as-contract tx-sender)))
        (map-set listings listing-id (merge {maker: tx-sender, nft-asset-contract: (contract-of nft-asset-contract)} nft-asset))
        (var-set listing-nonce (+ listing-is u1))
        (ok listing-id)
    )
)

(define-read-only (get-listing (listing-id uint))
 (map-get? listings listing-id)
)

(define-public (cancel-listing (listing-id uint) (nft-asset-contract <sip009-nft-trait>))
    (let (
         (listing (unwrap! (map-get? listings listing-id) err-unknown-listing))
          (maker (get maker listing))
        )
        (asserts! (is-eq maker tx-sender) err-unauthorised)
        (asserts! (is-eq (get nft-asset-contract listing) (contract-of nft-asset-contract)) err-nft-asset-mismatch)
        (map-delete listings listing-id)
        (as-contract (transfer-nft nft-asset-contract (get token-id listing) tx-sender maker))
    )
)