-- ============================================================
-- QUERY 6: High-Risk Segment Cross-Analysis
-- ============================================================
-- Business question: Which combinations of segment + fuel type
-- + transmission drive the worst loss ratios?
--
-- This is the kind of granular segmentation an analyst would
-- use to recommend targeted pricing adjustments.
-- Cross-tabs like this are standard in pricing committee packs.
-- ============================================================

SELECT
    segment,
    fuel_type,
    transmission_type,
    COUNT(*)                                                AS policies,
    SUM(claim_status)                                       AS claims,
    ROUND(AVG(claim_status) * 100, 2)                      AS claim_freq_pct,
    ROUND(AVG(annual_premium), 2)                          AS avg_premium,
    ROUND(SUM(claim_cost) / NULLIF(SUM(annual_premium), 0) * 100, 2) AS loss_ratio_pct
FROM insurance_claims
GROUP BY segment, fuel_type, transmission_type
HAVING COUNT(*) > 100       -- filter out thin segments (unreliable statistics)
ORDER BY loss_ratio_pct DESC
LIMIT 15;
