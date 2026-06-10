-- ============================================================
-- QUERY 2: Loss Ratio & Claim Frequency by Vehicle Segment
-- ============================================================
-- Business question: Which vehicle segments are most / least
-- profitable for the insurer?
--
-- Segments (proxy for vehicle class):
--   A = budget/city, B1/B2 = mainstream, C1/C2 = mid-range,
--   Utility = vans/commercial
--
-- Key metrics:
--   loss_ratio     = claims paid / premiums earned (lower = more profitable)
--   claim_frequency = proportion of policies that generated a claim
--   avg_claim_cost  = average severity when a claim does occur
-- ============================================================

SELECT
    segment,
    COUNT(*)                                                AS total_policies,
    SUM(claim_status)                                       AS claim_count,
    ROUND(AVG(claim_status) * 100, 2)                      AS claim_frequency_pct,
    ROUND(AVG(annual_premium), 2)                          AS avg_premium,
    ROUND(SUM(annual_premium), 2)                          AS total_premium,
    ROUND(SUM(claim_cost), 2)                              AS total_claims_paid,
    ROUND(AVG(claim_cost) FILTER (WHERE claim_status = 1), 2) AS avg_claim_cost,
    ROUND(SUM(claim_cost) / SUM(annual_premium) * 100, 2) AS loss_ratio_pct
FROM insurance_claims
GROUP BY segment
ORDER BY loss_ratio_pct DESC;
