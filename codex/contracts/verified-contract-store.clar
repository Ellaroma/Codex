;; Smart Contract Registry - Verified Contract Marketplace
;; Decentralized registry for audited and verified smart contracts

;; Constants
(define-constant registry-admin tx-sender)
(define-constant err-admin-only (err u500))
(define-constant err-contract-not-found (err u501))
(define-constant err-access-forbidden (err u502))
(define-constant err-payment-error (err u503))
(define-constant err-contract-exists (err u504))
(define-constant err-invalid-value (err u505))

;; Data Variables
(define-data-var registry-cut uint u400) ;; 4% registry fee

;; Data Maps
(define-map verified-contracts
  { contract-hash: (string-ascii 52) }
  {
    auditor: principal,
    contract-title: (string-utf8 100),
    contract-description: (string-utf8 500),
    use-case: (string-ascii 30), ;; "defi", "nft", "dao", "identity", "utility"
    license-cost: uint,
    template-cost: uint,
    deployment-count: uint,
    contract-revenue: uint,
    verified: bool,
    source-reference: (string-ascii 52) ;; IPFS hash of contract source
  }
)

(define-map developer-licenses
  { buyer: principal, contract-hash: (string-ascii 52) }
  {
    license-model: (string-ascii 8), ;; "template" or "license"
    purchased-at: uint,
    usage-limit: uint,
    amount-paid: uint
  }
)

(define-map contract-evaluations
  { contract-hash: (string-ascii 52), evaluator: principal }
  {
    trust-score: uint, ;; 1-5 trust rating
    evaluation: (string-utf8 400),
    evaluation-date: uint
  }
)

(define-map auditor-payments principal uint)

;; Read-only functions
(define-read-only (get-verified-contract (contract-hash (string-ascii 52)))
  (map-get? verified-contracts { contract-hash: contract-hash })
)

(define-read-only (get-developer-license (buyer principal) (contract-hash (string-ascii 52)))
  (map-get? developer-licenses { buyer: buyer, contract-hash: contract-hash })
)

(define-read-only (get-contract-evaluation (contract-hash (string-ascii 52)) (evaluator principal))
  (map-get? contract-evaluations { contract-hash: contract-hash, evaluator: evaluator })
)

(define-read-only (get-auditor-payment (auditor principal))
  (default-to u0 (map-get? auditor-payments auditor))
)

(define-read-only (has-license (buyer principal) (contract-hash (string-ascii 52)))
  (let (
    (license (get-developer-license buyer contract-hash))
  )
    (match license
      license-info
        (or 
          (> (get usage-limit license-info) u0)
          (is-eq (get license-model license-info) "template")
        )
      false
    )
  )
)

;; Public functions

;; Submit contract for verification
(define-public (submit-contract
    (contract-hash (string-ascii 52))
    (contract-title (string-utf8 100))
    (contract-description (string-utf8 500))
    (use-case (string-ascii 30))
    (license-cost uint)
    (template-cost uint)
    (source-reference (string-ascii 52))
  )
  (let (
    (existing-contract (get-verified-contract contract-hash))
  )
    (asserts! (is-none existing-contract) err-contract-exists)
    (ok (map-set verified-contracts
      { contract-hash: contract-hash }
      {
        auditor: tx-sender,
        contract-title: contract-title,
        contract-description: contract-description,
        use-case: use-case,
        license-cost: license-cost,
        template-cost: template-cost,
        deployment-count: u0,
        contract-revenue: u0,
        verified: false,
        source-reference: source-reference
      }
    ))
  )
)

;; Purchase full template rights
(define-public (purchase-template (contract-hash (string-ascii 52)))
  (let (
    (contract-info (unwrap! (get-verified-contract contract-hash) err-contract-not-found))
    (template-price (get template-cost contract-info))
    (registry-fee (/ (* template-price (var-get registry-cut)) u10000))
    (auditor-share (- template-price registry-fee))
  )
    (asserts! (get verified contract-info) err-contract-not-found)
    (try! (stx-transfer? template-price tx-sender (as-contract tx-sender)))
    
    ;; Update contract statistics
    (map-set verified-contracts
      { contract-hash: contract-hash }
      (merge contract-info {
        deployment-count: (+ (get deployment-count contract-info) u1),
        contract-revenue: (+ (get contract-revenue contract-info) template-price)
      })
    )
    
    ;; Grant template license
    (map-set developer-licenses
      { buyer: tx-sender, contract-hash: contract-hash }
      {
        license-model: "template",
        purchased-at: block-height,
        usage-limit: u999999, ;; Unlimited usage
        amount-paid: template-price
      }
    )
    
    ;; Credit auditor
    (map-set auditor-payments
      (get auditor contract-info)
      (+ (get-auditor-payment (get auditor contract-info)) auditor-share)
    )
    
    (ok true)
  )
)

;; Purchase limited usage license
(define-public (purchase-license (contract-hash (string-ascii 52)) (usage-count uint))
  (let (
    (contract-info (unwrap! (get-verified-contract contract-hash) err-contract-not-found))
    (total-cost (* (get license-cost contract-info) usage-count))
    (registry-fee (/ (* total-cost (var-get registry-cut)) u10000))
    (auditor-share (- total-cost registry-fee))
  )
    (asserts! (get verified contract-info) err-contract-not-found)
    (try! (stx-transfer? total-cost tx-sender (as-contract tx-sender)))
    
    ;; Update contract statistics
    (map-set verified-contracts
      { contract-hash: contract-hash }
      (merge contract-info {
        deployment-count: (+ (get deployment-count contract-info) u1),
        contract-revenue: (+ (get contract-revenue contract-info) total-cost)
      })
    )
    
    ;; Update or create license
    (let (
      (existing-license (get-developer-license tx-sender contract-hash))
    )
      (match existing-license
        license-info
          (map-set developer-licenses
            { buyer: tx-sender, contract-hash: contract-hash }
            (merge license-info {
              usage-limit: (+ (get usage-limit license-info) usage-count),
              amount-paid: (+ (get amount-paid license-info) total-cost)
            })
          )
        (map-set developer-licenses
          { buyer: tx-sender, contract-hash: contract-hash }
          {
            license-model: "license",
            purchased-at: block-height,
            usage-limit: usage-count,
            amount-paid: total-cost
          }
        )
      )
    )
    
    ;; Credit auditor
    (map-set auditor-payments
      (get auditor contract-info)
      (+ (get-auditor-payment (get auditor contract-info)) auditor-share)
    )
    
    (ok true)
  )
)

;; Deploy contract (consumes license usage)
(define-public (deploy-contract (contract-hash (string-ascii 52)))
  (let (
    (contract-info (unwrap! (get-verified-contract contract-hash) err-contract-not-found))
    (license (unwrap! (get-developer-license tx-sender contract-hash) err-access-forbidden))
  )
    (asserts! (get verified contract-info) err-contract-not-found)
    
    ;; Check and consume usage rights
    (if (is-eq (get license-model license) "license")
      (begin
        (asserts! (> (get usage-limit license) u0) err-access-forbidden)
        (map-set developer-licenses
          { buyer: tx-sender, contract-hash: contract-hash }
          (merge license {
            usage-limit: (- (get usage-limit license) u1)
          })
        )
        (ok true)
      )
      (ok true) ;; Template license has unlimited usage
    )
  )
)

;; Evaluate deployed contract
(define-public (evaluate-contract
    (contract-hash (string-ascii 52))
    (trust-score uint)
    (evaluation (string-utf8 400))
  )
  (let (
    (contract-info (unwrap! (get-verified-contract contract-hash) err-contract-not-found))
  )
    (asserts! (and (>= trust-score u1) (<= trust-score u5)) err-invalid-value)
    (asserts! (has-license tx-sender contract-hash) err-access-forbidden)
    
    (ok (map-set contract-evaluations
      { contract-hash: contract-hash, evaluator: tx-sender }
      {
        trust-score: trust-score,
        evaluation: evaluation,
        evaluation-date: block-height
      }
    ))
  )
)

;; Auditor claims payment
(define-public (claim-auditor-payment)
  (let (
    (payment (get-auditor-payment tx-sender))
  )
    (asserts! (> payment u0) err-contract-not-found)
    (try! (as-contract (stx-transfer? payment tx-sender tx-sender)))
    (map-set auditor-payments tx-sender u0)
    (ok payment)
  )
)

;; Update contract information
(define-public (update-contract-info
    (contract-hash (string-ascii 52))
    (contract-title (string-utf8 100))
    (contract-description (string-utf8 500))
    (license-cost uint)
    (template-cost uint)
    (source-reference (string-ascii 52))
    (verified bool)
  )
  (let (
    (contract-info (unwrap! (get-verified-contract contract-hash) err-contract-not-found))
  )
    (asserts! (is-eq (get auditor contract-info) tx-sender) err-access-forbidden)
    
    (ok (map-set verified-contracts
      { contract-hash: contract-hash }
      (merge contract-info {
        contract-title: contract-title,
        contract-description: contract-description,
        license-cost: license-cost,
        template-cost: template-cost,
        source-reference: source-reference,
        verified: verified
      })
    ))
  )
)

;; Admin function to update registry fee
(define-public (update-registry-cut (new-cut uint))
  (begin
    (asserts! (is-eq tx-sender registry-admin) err-admin-only)
    (asserts! (<= new-cut u2000) err-invalid-value) ;; Max 20%
    (ok (var-set registry-cut new-cut))
  )
)