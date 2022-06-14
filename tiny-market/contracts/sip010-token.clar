(impl-trait .sip010-ft-trait.sip010-ft-trait)

(define-fungible-token AnG-coin u10000000)

(ft-mint? AnG-coin u10000 tx-sender)

;;(ft-transfer? AnG-coin u500 tx-sender principal)

;;get and print the token balance of tx-sender
(print (ft-get-balance AnG-coin tx-sender))

;;burn 250 tokens
;;(ft-burn? AnG-coin u250 principal)

(print (ft-get-supply AnG-coin))
