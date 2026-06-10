# Motor Insurance Risk & Pricing Analysis

An end-to-end data analysis project examining claim risk, loss ratios, and pricing adequacy across a motor insurance portfolio of 58,592 policies. Built to demonstrate data analyst skills relevant to insurance and financial services roles.

---

## Project Overview

**Business Question:** Which customer and vehicle segments carry the highest claim risk, and are current premiums adequate relative to that risk?

This project mirrors the core analytical workflow of an insurance pricing or risk analyst team:

1. **Data engineering** — actuarial premium and claim cost variables derived from first principles using a GLM-style multiplicative rating structure
2. **SQL analysis** — 10 queries covering loss ratio, claim frequency, severity distribution, and segment pricing flags
3. **Python analysis** — exploratory data analysis, loss ratio modelling, and a logistic regression claim probability model
4. **Excel scenario model** — pricing adjustment scenarios showing P&L impact of rate changes by segment
5. **Power BI dashboard** — 4-page interactive dashboard for segment analysis and pricing review (available on request / see PDF export in repo)

---

## Key Findings

- **Segment B2** carries the highest loss ratio at **33.9%**, 4.3 percentage points above the portfolio average, indicating potential underpricing relative to actual claim experience
- **Utility segment** is the most profitable at **19.1%** loss ratio, suggesting headroom for competitive pricing to grow market share
- Policies with **all 5 safety features** (ESC, brake assist, TPMS, parking camera, parking sensors) have a claim frequency of **6.4%** vs **6.1%** for policies with none — validating the premium discounts applied, though the marginal impact is modest in this dataset
- A **logistic regression model** (AUC = 0.556) identifies vehicle segment, engine displacement, and region density as the strongest predictors of claim probability — consistent with standard actuarial pricing factors
- **Large claims (>£15k)** account for only 3.2% of claim count but a disproportionate share of total claims cost, highlighting the importance of reinsurance above a high excess point

---

## Methodology Note — Engineered Variables

Real insurers treat premium and claim cost data as commercially sensitive, so no public dataset provides both at policy level. `annual_premium` and `claim_cost` were therefore engineered using actuarial pricing principles:

**Annual premium** — calculated using a multiplicative GLM structure (the industry standard for motor pricing) with seven rating factors applied to a segment base premium: customer age, vehicle age, engine displacement, fuel type, transmission type, safety features (ESC, brake assist, NCAP rating, airbags), and urban density. Individual underwriting noise of ±5% was added to simulate real-world variation.

**Claim cost** — drawn from a log-normal distribution (the standard actuarial severity assumption) calibrated to the ABI UK motor market benchmark of ~£3,200 average claim cost.

The portfolio loss ratio of ~30% reflects the dataset's 6.4% claim frequency, which is lower than the UK market average of ~20–25% (ABI). Premiums and claim costs are individually calibrated to market benchmarks; relative loss ratio comparisons across segments are analytically valid.

---

## Repository Structure

```
data-analysis-project/
│
├── notebooks/
│   └── insurance_risk_analysis.ipynb   # Full Python analysis notebook
│
├── sql/
│   ├── 00_setup_and_import.md          # PostgreSQL setup guide
│   ├── 01_portfolio_overview.sql
│   ├── 02_loss_ratio_by_segment.sql
│   ├── 03_loss_ratio_by_region.sql
│   ├── 04_loss_ratio_by_age_band.sql
│   ├── 05_claim_severity_distribution.sql
│   ├── 06_high_risk_segment_crosstab.sql
│   ├── 07_safety_features_impact.sql
│   ├── 08_vehicle_age_analysis.sql
│   ├── 09_top10_largest_claims.sql
│   └── 10_underpriced_segment_flags.sql
│
├── engineer_features/
│   └── engineer_insurance_features.py  # Premium & claim cost engineering script
│
└── README.md
```

---

## Tools & Techniques

| Tool | Usage |
|------|-------|
| **Python** (Pandas, NumPy, Scikit-learn, Matplotlib, Seaborn) | Data engineering, EDA, logistic regression model |
| **SQL** (PostgreSQL) | Portfolio aggregation, loss ratio analysis, segment flagging |
| **Excel** | Pricing scenario model, combined ratio sensitivity analysis |
| **Power BI** | Interactive stakeholder dashboard |

**SQL concepts demonstrated:** CTEs, window functions, CASE WHEN banding, FILTER clause, HAVING, NULLIF, CROSS JOIN for portfolio benchmarking

**Python concepts demonstrated:** Feature engineering, log-normal distribution fitting, GLM-style multiplicative modelling, logistic regression with class imbalance handling, ROC-AUC evaluation

---

## Data Source

**Dataset:** Motor Insurance Claims — [Kaggle](https://www.kaggle.com/)  
58,592 policies | 41 original features | 3 engineered variables (`annual_premium`, `claim_cost`, `loss_ratio`)

The raw dataset is not included in this repository. Download it from Kaggle and run `engineer_features/engineer_insurance_features.py` to reproduce the engineered dataset used in the analysis.

---

## Author

**Rathushan Rathasethupathy**  
MEng Aerospace Engineering, University of Surrey  
[LinkedIn](https://linkedin.com/in/rathushanr) | rathus14@gmail.com
