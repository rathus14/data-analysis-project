-- ============================================================
-- QUERY 1: Portfolio Overview
-- ============================================================
-- Business question: What does the overall portfolio look like?
-- This is your executive summary — the first thing you'd show
-- a manager before drilling into segment detail.
-- ============================================================

SELECT
    COUNT(*)                                        AS total_policies,
    SUM(claim_status)                               AS total_claims,
    ROUND(AVG(claim_status) * 100, 2)              AS claim_frequency_pct,
    ROUND(AVG(annual_premium), 2)                  AS avg_premium,
    ROUND(SUM(annual_premium), 2)                  AS total_premium_earned,
    ROUND(SUM(claim_cost), 2)                      AS total_claims_paid,
    ROUND(SUM(claim_cost) / SUM(annual_premium) * 100, 2) AS portfolio_loss_ratio_pct
FROM insurance_claims;
