-- ============================================================
-- QUERY 5: Claim Severity Distribution
-- ============================================================
-- Business question: What is the shape of claim costs?
-- Insurers need to understand severity bands to set reserves
-- correctly and identify outlier large claims.
--
-- Severity buckets:
--   Attritional  = <£1,000   (minor incidents, high frequency)
--   Mid-range    = £1k-£5k   (standard claims, bulk of cost)
--   Large        = £5k-£15k  (serious incidents)
--   Major        = >£15k     (catastrophic / total loss)
-- ============================================================

SELECT
    CASE
        WHEN claim_cost < 1000              THEN '1. Attritional (<£1k)'
        WHEN claim_cost < 5000              THEN '2. Mid-range (£1k-£5k)'
        WHEN claim_cost < 15000             THEN '3. Large (£5k-£15k)'
        ELSE                                     '4. Major (>£15k)'
    END                                         AS severity_band,
    COUNT(*)                                    AS claim_count,
    ROUND(AVG(claim_cost), 2)                  AS avg_claim_cost,
    ROUND(MIN(claim_cost), 2)                  AS min_claim,
    ROUND(MAX(claim_cost), 2)                  AS max_claim,
    ROUND(SUM(claim_cost), 2)                  AS total_cost,
    ROUND(SUM(claim_cost) / SUM(SUM(claim_cost)) OVER () * 100, 2) AS pct_of_total_cost
FROM insurance_claims
WHERE claim_status = 1
GROUP BY severity_band
ORDER BY severity_band;
