-- ============================================================
-- QUERY 10: Underpriced Segment Flagging
-- ============================================================
-- Business question: Which segments have a loss ratio
-- significantly above the portfolio average — indicating the
-- premium charged may be insufficient for the risk?
--
-- This is the core commercial insight of the project.
-- A segment running 20%+ above the portfolio average loss ratio
-- would typically trigger a pricing review.
--
-- Uses a CTE + WINDOW FUNCTION — demonstrates advanced SQL.
-- ============================================================

WITH portfolio AS (
    SELECT
        ROUND(SUM(claim_cost) / SUM(annual_premium) * 100, 2) AS portfolio_lr
    FROM insurance_claims
),
segment_summary AS (
    SELECT
        segment,
        fuel_type,
        COUNT(*)                                                            AS policies,
        ROUND(AVG(claim_status) * 100, 2)                                  AS claim_freq_pct,
        ROUND(AVG(annual_premium), 2)                                      AS avg_premium,
        ROUND(SUM(claim_cost) / NULLIF(SUM(annual_premium), 0) * 100, 2)  AS segment_lr
    FROM insurance_claims
    GROUP BY segment, fuel_type
    HAVING COUNT(*) > 200
)
SELECT
    s.segment,
    s.fuel_type,
    s.policies,
    s.claim_freq_pct,
    s.avg_premium,
    s.segment_lr,
    p.portfolio_lr,
    ROUND(s.segment_lr - p.portfolio_lr, 2)                                AS lr_vs_portfolio,
    CASE
        WHEN s.segment_lr > p.portfolio_lr * 1.20 THEN 'FLAG: Potential underpricing'
        WHEN s.segment_lr < p.portfolio_lr * 0.80 THEN 'Review: Possible overpricing'
        ELSE 'Within acceptable range'
    END                                                                     AS pricing_flag
FROM segment_summary s
CROSS JOIN portfolio p
ORDER BY lr_vs_portfolio DESC;
