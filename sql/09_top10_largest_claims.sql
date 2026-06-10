-- ============================================================
-- QUERY 9: Top 10 Most Costly Claims
-- ============================================================
-- Business question: What do the largest individual claims
-- look like — what segments and risk profiles produce them?
--
-- Large claim analysis is used in reinsurance decisions
-- (deciding how much risk to cede to a reinsurer above a
-- certain threshold). Interviewers at insurers will recognise
-- this kind of query immediately.
-- ============================================================

SELECT
    policy_id,
    segment,
    fuel_type,
    transmission_type,
    customer_age,
    vehicle_age,
    ncap_rating,
    region_code,
    ROUND(annual_premium, 2)    AS annual_premium,
    ROUND(claim_cost, 2)        AS claim_cost,
    ROUND(loss_ratio, 2)        AS policy_loss_ratio
FROM insurance_claims
WHERE claim_status = 1
ORDER BY claim_cost DESC
LIMIT 10;
