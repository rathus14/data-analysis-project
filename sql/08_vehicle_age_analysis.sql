-- ============================================================
-- QUERY 8: Vehicle Age vs Claim Frequency and Severity
-- ============================================================
-- Business question: How does vehicle age affect both how
-- often claims occur and how much they cost?
--
-- This matters for pricing because:
--   - New vehicles: expensive to repair (parts, tech)
--   - Mid-age (3-6 years): optimal risk
--   - Old vehicles: higher breakdown/failure risk
--
-- Uses WINDOW FUNCTION to show each band vs portfolio average —
-- a more advanced SQL technique worth highlighting on your CV.
-- ============================================================

WITH age_bands AS (
    SELECT
        CASE
            WHEN vehicle_age < 1  THEN '0. Brand new (<1yr)'
            WHEN vehicle_age < 3  THEN '1. Nearly new (1-3yr)'
            WHEN vehicle_age < 6  THEN '2. Mid-age (3-6yr)'
            WHEN vehicle_age < 10 THEN '3. Older (6-10yr)'
            ELSE                       '4. High age (10yr+)'
        END                                                 AS vehicle_age_band,
        claim_status,
        annual_premium,
        claim_cost
    FROM insurance_claims
),
summary AS (
    SELECT
        vehicle_age_band,
        COUNT(*)                                            AS policies,
        SUM(claim_status)                                   AS claims,
        ROUND(AVG(claim_status) * 100, 2)                  AS claim_freq_pct,
        ROUND(AVG(claim_cost) FILTER (WHERE claim_status = 1), 2) AS avg_claim_cost,
        ROUND(SUM(claim_cost) / NULLIF(SUM(annual_premium), 0) * 100, 2) AS loss_ratio_pct
    FROM age_bands
    GROUP BY vehicle_age_band
)
SELECT
    *,
    ROUND(claim_freq_pct - AVG(claim_freq_pct) OVER (), 2) AS freq_vs_portfolio_avg
FROM summary
ORDER BY vehicle_age_band;
