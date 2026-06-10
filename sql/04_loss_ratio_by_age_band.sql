-- ============================================================
-- QUERY 4: Loss Ratio by Customer Age Band
-- ============================================================
-- Business question: How does policyholder age affect
-- profitability? This validates whether the age rating factors
-- built into the premium are correctly calibrated.
--
-- If a younger age band has high claim frequency but lower
-- premiums than warranted, that's evidence of underpricing.
-- ============================================================

SELECT
    CASE
        WHEN customer_age < 40 THEN '35-39'
        WHEN customer_age < 45 THEN '40-44'
        WHEN customer_age < 50 THEN '45-49'
        WHEN customer_age < 55 THEN '50-54'
        WHEN customer_age < 60 THEN '55-59'
        WHEN customer_age < 65 THEN '60-64'
        ELSE                        '65+'
    END                                                     AS age_band,
    COUNT(*)                                                AS total_policies,
    SUM(claim_status)                                       AS claim_count,
    ROUND(AVG(claim_status) * 100, 2)                      AS claim_frequency_pct,
    ROUND(AVG(annual_premium), 2)                          AS avg_premium,
    ROUND(AVG(claim_cost) FILTER (WHERE claim_status = 1), 2) AS avg_claim_cost,
    ROUND(SUM(claim_cost) / SUM(annual_premium) * 100, 2) AS loss_ratio_pct
FROM insurance_claims
GROUP BY age_band
ORDER BY age_band;
