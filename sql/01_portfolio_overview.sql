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
