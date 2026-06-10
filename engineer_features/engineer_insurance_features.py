"""
engineer_insurance_features.py
================================
Engineers two financially meaningful columns into the insurance claims dataset:
  - annual_premium  : estimated premium the insurer charges the policyholder (£)
  - claim_cost      : estimated cost of the claim to the insurer (£, 0 if no claim)

METHODOLOGY NOTE (for README / interviews)
-------------------------------------------
Real insurers keep premium and claim cost data proprietary.  This script
derives realistic approximations using actuarial pricing principles:

  1. A base premium is set by vehicle segment (proxy for vehicle value/risk class).
  2. Rating factors — the standard building blocks of a Generalised Linear Model
     (GLM) used by pricing actuaries — are applied multiplicatively.
  3. Claim costs are drawn from a log-normal distribution whose parameters
     (mean, variance) are calibrated to approximate UK motor market benchmarks
     (average claim ~£3,200, as reported in ABI market data).
  4. A random seed is fixed so results are fully reproducible.

The approach intentionally mirrors how insurers actually price risk, making
the engineered columns analytically valid for loss ratio and segment analysis.
"""

import pandas as pd
import numpy as np

# ── Reproducibility ──────────────────────────────────────────────────────────
SEED = 42
rng = np.random.default_rng(SEED)

# ── Load data ─────────────────────────────────────────────────────────────────
df = pd.read_csv('/mnt/user-data/uploads/Insurance_claims_data.csv')
print(f"Loaded {len(df):,} rows")

# =============================================================================
# STEP 1 — BASE PREMIUM BY VEHICLE SEGMENT
# =============================================================================
# Segments proxy vehicle value / engine size / risk class.
# Base premiums are calibrated to approximate UK motor insurance market averages
# (ABI data: average UK motor premium ~£550-650 for standard vehicles, higher
# for performance/utility segments).
#
#   A       = budget / small city cars       (~800cc-1000cc)
#   B1/B2   = mainstream family cars         (~1000cc-1300cc)
#   C1/C2   = mid-range / larger family cars (~1300cc-1500cc)
#   Utility = vans / commercial vehicles     (higher risk loading)

BASE_PREMIUM = {
    'A':       480,
    'B1':      560,
    'B2':      590,
    'C1':      680,
    'C2':      720,
    'Utility': 810,
}
df['_base'] = df['segment'].map(BASE_PREMIUM)

# =============================================================================
# STEP 2 — RATING FACTORS  (multiplicative GLM-style adjustments)
# =============================================================================

# ── 2a. Age factor ────────────────────────────────────────────────────────────
# Younger and older drivers carry higher risk.  Standard industry shape:
#   35-44 → neutral (1.0), 45-54 → slight discount, 55+ → slight loading,
#   but dataset floor is 35 so we don't model the <25 spike.
def age_factor(age):
    if age < 40:   return 1.12   # less experienced, higher claim rate
    elif age < 50: return 1.00   # core low-risk cohort
    elif age < 60: return 0.95   # still experienced, slight discount
    else:          return 1.08   # older drivers, slower reactions loading

df['_f_age'] = df['customer_age'].apply(age_factor)

# ── 2b. Vehicle age factor ────────────────────────────────────────────────────
# Newer vehicles cost more to repair (parts, sensors, ADAS).
# Older vehicles have higher mechanical failure risk.
# Optimal point around 2-5 years.
def vehicle_age_factor(vage):
    if vage < 1:    return 1.15   # brand new — high repair cost loading
    elif vage < 3:  return 1.05
    elif vage < 6:  return 1.00   # sweet spot
    elif vage < 10: return 1.08   # aging vehicle loading
    else:           return 1.18   # high age / classic — higher risk

df['_f_vage'] = df['vehicle_age'].apply(vehicle_age_factor)

# ── 2c. Engine displacement factor ───────────────────────────────────────────
# Larger engines → higher performance → higher claim severity.
# Split into terciles based on observed data range (796–1498cc).
def displacement_factor(disp):
    if disp < 1000:  return 0.92   # small engine discount
    elif disp < 1300: return 1.00  # mid-range neutral
    else:             return 1.10  # larger engine loading

df['_f_disp'] = df['displacement'].apply(displacement_factor)

# ── 2d. Fuel type factor ──────────────────────────────────────────────────────
# Diesel: slightly higher repair cost but lower frequency historically.
# CNG:    less common, parts harder to source → higher repair cost.
FUEL_FACTOR = {'Petrol': 1.00, 'Diesel': 0.97, 'CNG': 1.06}
df['_f_fuel'] = df['fuel_type'].map(FUEL_FACTOR)

# ── 2e. Transmission factor ───────────────────────────────────────────────────
# Automatic transmissions are more expensive to repair.
TRANS_FACTOR = {'Manual': 1.00, 'Automatic': 1.05}
df['_f_trans'] = df['transmission_type'].map(TRANS_FACTOR)

# ── 2f. Safety features discount ─────────────────────────────────────────────
# Insurers give discounts for active safety tech that reduces claim frequency.
# ESC (electronic stability control) and brake assist have strongest evidence.
# NCAP rating is a direct insurer input.
def safety_discount(row):
    discount = 1.00
    if row['is_esc'] == 'Yes':          discount -= 0.04
    if row['is_brake_assist'] == 'Yes': discount -= 0.03
    if row['is_tpms'] == 'Yes':         discount -= 0.01
    if row['is_parking_camera'] == 'Yes': discount -= 0.01
    if row['airbags'] >= 4:             discount -= 0.02   # additional airbags
    # NCAP: 5-star = 4% discount, 4-star = 2%, 0-star = 3% loading
    ncap_adj = {0: 0.03, 2: 0.00, 3: -0.01, 4: -0.02, 5: -0.04}
    discount += ncap_adj.get(row['ncap_rating'], 0.00)
    return max(discount, 0.75)  # cap total discount at 25%

df['_f_safety'] = df.apply(safety_discount, axis=1)

# ── 2g. Urban density factor ──────────────────────────────────────────────────
# Higher population density → more congestion → higher claim frequency.
# Calibrated against region_density quartiles in this dataset.
density_q = df['region_density'].quantile([0.25, 0.50, 0.75])
def density_factor(d):
    if d < density_q[0.25]:  return 0.93  # rural — lower frequency
    elif d < density_q[0.50]: return 1.00
    elif d < density_q[0.75]: return 1.07
    else:                      return 1.14  # dense urban — higher frequency

df['_f_density'] = df['region_density'].apply(density_factor)

# =============================================================================
# STEP 3 — CALCULATE ANNUAL PREMIUM
# =============================================================================
# Multiply base by all rating factors, then add a small noise term (±5%)
# to simulate individual underwriting variation (no two risks are identical).

df['annual_premium'] = (
    df['_base']
    * df['_f_age']
    * df['_f_vage']
    * df['_f_disp']
    * df['_f_fuel']
    * df['_f_trans']
    * df['_f_safety']
    * df['_f_density']
    * rng.uniform(0.95, 1.05, size=len(df))   # individual underwriting noise
).round(2)

# =============================================================================
# STEP 4 — SIMULATE CLAIM COST (log-normal distribution)
# =============================================================================
# Claim costs follow a log-normal distribution — a standard actuarial assumption
# for severity modelling (right-skewed: most claims are modest, few are very large).
#
# Parameters calibrated to UK motor market benchmarks:
#   - Mean claim cost ≈ £3,200  (ABI industry average)
#   - Standard deviation ≈ £2,800 (high variance is realistic for motor)
#
# Log-normal parameters derived from:
#   mu    = ln(mean²  / sqrt(variance + mean²))
#   sigma = sqrt(ln(1 + variance/mean²))

CLAIM_MEAN = 3200   # ABI UK motor average claim cost benchmark
CLAIM_STD  = 2800

# ANALYST NOTE — why the portfolio loss ratio will be low (~30%):
# This dataset has a claim frequency of 6.4% (3,748 / 58,592 policies).
# The real UK motor market runs ~20-25% frequency (ABI data).
# With realistic premiums (~£691) and realistic claim costs (~£3,200),
# the pure loss ratio is mechanically determined by frequency:
#   LR ≈ frequency × avg_claim / avg_premium = 6.4% × £3,200 / £691 = ~30%
# This is documented transparently in the project README.
# The dataset is still analytically valid for *relative* loss ratio comparisons
# across segments — which segments run higher/lower than the portfolio average
# is meaningful regardless of the absolute level.

mu    = np.log(CLAIM_MEAN**2 / np.sqrt(CLAIM_STD**2 + CLAIM_MEAN**2))
sigma = np.sqrt(np.log(1 + (CLAIM_STD / CLAIM_MEAN)**2))

# Draw a cost for every row; then zero out non-claimants
raw_costs = rng.lognormal(mean=mu, sigma=sigma, size=len(df))
df['claim_cost'] = np.where(df['claim_status'] == 1, raw_costs.round(2), 0.00)

# =============================================================================
# STEP 5 — DERIVE LOSS RATIO  (policy-level and useful for segment aggregation)
# =============================================================================
# Loss ratio = claim_cost / annual_premium
# At policy level this is either 0 (no claim) or >0 (claim made).
# The meaningful metric is calculated at segment level in your SQL/Python analysis.
df['loss_ratio'] = (df['claim_cost'] / df['annual_premium']).round(4)

# =============================================================================
# STEP 6 — DROP INTERMEDIATE COLUMNS AND SAVE
# =============================================================================
drop_cols = [c for c in df.columns if c.startswith('_')]
df.drop(columns=drop_cols, inplace=True)

output_path = '/home/claude/insurance_claims_engineered.csv'
df.to_csv(output_path, index=False)
print(f"Saved to {output_path}")

# =============================================================================
# STEP 7 — VALIDATION SUMMARY
# =============================================================================
print("\n── Premium summary ──────────────────────────────────────────")
print(df['annual_premium'].describe().round(2))

print("\n── Claim cost summary (claimants only) ─────────────────────")
claimants = df[df['claim_status'] == 1]['claim_cost']
print(claimants.describe().round(2))

print("\n── Segment-level loss ratio ─────────────────────────────────")
seg = df.groupby('segment').agg(
    policies        = ('policy_id', 'count'),
    total_premium   = ('annual_premium', 'sum'),
    total_claims    = ('claim_cost', 'sum'),
    claim_count     = ('claim_status', 'sum'),
).assign(
    loss_ratio      = lambda x: (x['total_claims'] / x['total_premium']).round(4),
    claim_frequency = lambda x: (x['claim_count']  / x['policies']).round(4),
).sort_values('loss_ratio', ascending=False)
print(seg.to_string())

print("\n── Overall portfolio loss ratio ─────────────────────────────")
overall_lr = df['claim_cost'].sum() / df['annual_premium'].sum()
print(f"  {overall_lr:.2%}  (UK motor market benchmark: 70–80%)")
