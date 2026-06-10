-- ============================================================
-- QUERY 3: Loss Ratio & Claim Frequency by Region
-- ============================================================
-- Business question: Are there geographic hotspots where the
-- insurer is losing more money than average?
--
-- Regions with loss_ratio_pct significantly above the portfolio
-- average (~30%) warrant investigation — either underpricing
-- in that area, or higher underlying risk (urban density,
-- road quality, crime rate).
-- ============================================================

SELECT
    region_code,
    COUNT(*)                                                AS total_policies,
    SUM(claim_status)                                       AS claim_count,
    ROUND(AVG(claim_status) * 100, 2)                      AS claim_frequency_pct,
    ROUND(AVG(annual_premium), 2)                          AS avg_premium,
    ROUND(AVG(region_density), 0)                          AS avg_region_density,
    ROUND(SUM(claim_cost) / SUM(annual_premium) * 100, 2) AS loss_ratio_pct
FROM insurance_claims
GROUP BY region_code
ORDER BY loss_ratio_pct DESC
LIMIT 10;
