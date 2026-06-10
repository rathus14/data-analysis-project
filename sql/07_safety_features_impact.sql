-- ============================================================
-- QUERY 7: Impact of Safety Features on Claim Frequency
-- ============================================================
-- Business question: Do safety features actually reduce claims,
-- and are the premium discounts we give for them justified?
--
-- This is a direct test of whether our pricing assumptions
-- are commercially valid — a great talking point in interviews.
--
-- If ESC reduces claim frequency by 15% but we only give a 4%
-- discount, the pricing is conservative (good for the insurer).
-- If the discount exceeds the actual reduction, it's too generous.
-- ============================================================

SELECT
    is_esc,
    is_brake_assist,
    ncap_rating,
    COUNT(*)                                                AS policies,
    ROUND(AVG(claim_status) * 100, 2)                      AS claim_frequency_pct,
    ROUND(AVG(annual_premium), 2)                          AS avg_premium,
    ROUND(SUM(claim_cost) / NULLIF(SUM(annual_premium), 0) * 100, 2) AS loss_ratio_pct
FROM insurance_claims
GROUP BY is_esc, is_brake_assist, ncap_rating
HAVING COUNT(*) > 200
ORDER BY claim_frequency_pct DESC;
