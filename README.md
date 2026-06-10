# Motor Insurance Risk & Pricing Analysis

An end-to-end data analysis project examining claim risk and loss ratios across a motor insurance portfolio of 58,592 policies. Built as a portfolio project to develop data analyst skills for insurance and financial services roles.

## Project Overview

**Main question:** Which customer and vehicle segments are the most profitable, and which segments might be underpriced relative to their actual claim risk?

The project covers the main skills an insurance analyst needs:

1. **Data engineering** - created realistic premium and claim cost variables using actuarial pricing principles
2. **SQL analysis** - 10 queries looking at loss ratio by segment, region, age band, and claim severity
3. **Python analysis** - exploratory analysis, loss ratio breakdown by segment, and a logistic regression model to predict claim probability
4. **Excel model** - pricing scenario analysis showing what happens if we adjust rates on high-risk segments
5. **Power BI dashboard** - [see PDF export](insurance_risk_analysis_dashboard.pdf) with 4 pages covering portfolio overview, segment analysis, claim severity, and pricing flags

---

## Key Findings

- Segment B2 has the highest loss ratio at 33.9%, which is 4.3pp above the portfolio average - suggests the premium may be too low for the actual claim risk
- Utility segment is the most profitable at 19.1% - there's room to offer more competitive rates and grow market share here
- The logistic regression model (AUC 0.556) shows that vehicle segment, engine displacement, and region density are the strongest predictors of whether a policy will have a claim
- Large claims (over £15k) are only 3.2% of claims by count but make up a much larger share of total cost - suggests reinsurance above a £15k excess makes sense
- Policies with safety features (ESC, brake assist, TPMS) do have slightly lower claim frequency, which validates applying premium discounts for them

---

## About the Data

The dataset has 58,592 policies but didn't originally include premium or claim amounts. Real insurance data like that is confidential, so I engineered these columns using standard actuarial pricing:

- **Premiums** - calculated using a GLM (generalised linear model) rating structure with 7 factors: customer age, vehicle age, engine size, fuel type, transmission, safety features, and region density. Added ±5% random noise to simulate real underwriting differences.
- **Claims** - drawn from a log-normal distribution with mean £3,200, which matches the ABI UK benchmark for motor claims.

The portfolio loss ratio comes out at around 30%, which is lower than the UK market (which runs 70-80%) because the dataset has a lower claim frequency (6.4% vs 20-25% market). But the comparisons between segments are still valid - if segment B2 has a 34% loss ratio and segment C2 has 24%, that difference is real and meaningful.

---

## Repo Contents

```
notebooks/           - main Python analysis and EDA
sql/                 - 10 SQL queries for portfolio analysis
engineer_features/   - Python script that created the premium and claim cost columns
dashboard/           - PDF export of the Power BI dashboard
```

---

## Tools & Skills Demonstrated

**Python** - Pandas, NumPy, Scikit-learn, feature engineering, logistic regression, ROC-AUC evaluation

**SQL** - PostgreSQL, CTEs, window functions, CASE WHEN, HAVING, CROSS JOIN for portfolio benchmarking

**Excel** - scenario modelling, sensitivity analysis with formulas

**Power BI** - 4-page interactive dashboard with slicers, heatmaps, KPI cards

---

**Author:** Rathushan Rathasethupathy  
[LinkedIn](https://linkedin.com/in/rathushanr) | rathus14@gmail.com
