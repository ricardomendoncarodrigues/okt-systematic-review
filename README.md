# Orthotopic Kidney Transplantation in Adults — Systematic Review and Meta-analysis

Data and analysis code for the systematic review and meta-analysis **"Orthotopic Kidney Transplantation in Adults: A Systematic Review and Meta-analysis of Indications, Surgical Technique and Outcomes"**.

**Authors:** Ricardo Mendonça Rodrigues, Alberto Costa Silva, Teresa Pina Vaz, Tiago Antunes-Lopes, João Alturas Silva

**Affiliation:** São João Local Health Unit, Porto, Portugal; Faculty of Medicine of the University of Porto (FMUP), Porto, Portugal

- **Protocol registration:** PROSPERO CRD420261415834
- **Reporting guideline:** PRISMA 2020
- **Article:** *under review — link and DOI will be added on publication*

## Summary

Nine case series (265 recipients, published 1989–2024) reporting orthotopic kidney transplantation (OKT) were included. Binary outcomes were pooled as proportions using random-effects binomial generalised linear mixed models (GLMM, logit link) with Hartung–Knapp–Sidik–Jonkman (HKSJ) confidence intervals and 95% prediction intervals. Robustness was assessed with leave-one-out analysis and, post hoc, with a meta-regression on publication year and an open vs robot-assisted subgroup comparison.

## Repository contents

```
okt-systematic-review/
├── code/
│   └── OKT_meta_analysis.R              Full analysis: primary GLMM, leave-one-out,
│                                        era meta-regression, subgroup analysis, forest plots
├── data/
│   ├── extraction_table.csv             Full data-extraction table (one row per included study)
│   ├── study_event_counts.csv           Per-study numerators/denominators used in the meta-analysis
│   ├── derivation_notes.csv             How each numerator and denominator was derived
│   └── R_input_data.xlsx                The three tables above in one workbook (+ long format)
├── results/
│   ├── Meta_analysis_results.xlsx       All analysis results (one sheet per analysis)
│   ├── primary_analysis.csv             Pooled estimates, 95% CI, 95% PI, I², τ²
│   ├── leave_one_out.csv
│   ├── era_meta_regression.csv
│   ├── subgroup_open_vs_robotic.csv
│   └── forest_plots/                    Forest plots for every outcome
└── supplementary/
    ├── search_strategies.md             Database search strings (last updated 3 June 2026)
    ├── PRISMA_flow_diagram.pdf
    ├── risk_of_bias_JBI.csv             JBI Critical Appraisal Checklist for Case Series
    └── GRADE_summary_of_findings.csv    Certainty of evidence per outcome
```

## Included studies

| Label in data | Study | n | Approach |
|---|---|---|---|
| Gil-Vernet (Historical HdC) | Historical Hospital de Clínic Cohort — Gil-Vernet JM et al. *J Urol* 1989;142:248–52. doi:10.1016/S0022-5347(17)38721-9 (updated data from Musquera et al. 2010) | 123 | Open |
| Paduch | Paduch DA et al. *J Urol* 2001;166:1647–50. doi:10.1016/S0022-5347(05)65645-5 | 5 | Open |
| Rodrigues | Rodrigues P et al. *Urol Int* 2004;73:316–9. doi:10.1159/000081591 | 4 | Open |
| De Gracia | De Gracia R et al. *Actas Urol Esp* 2007;31:1123–8 | 6 | Open |
| Musquera (Contemporary HdC) | Contemporary Hospital de Clínic Cohort — Musquera M et al. *Eur Urol* 2010;58:927–33. doi:10.1016/j.eururo.2010.09.023 | 84 | Open |
| Chan | Chan E et al. *Can Urol Assoc J* 2019;13(5). doi:10.5489/cuaj.5515 | 3 | Open |
| Gutiérrez-Zurimendi | Gutiérrez-Zurimendi G et al. *Arch Esp Urol* 2021;74:293–8 | 3 | Open |
| Medina | Artiles Medina A et al. *Adv Urol* 2022;2022:9299397. doi:10.1155/2022/9299397 | 21 | Open |
| Vigues | Vigués F et al. *Eur Urol* 2024;85:556–64. doi:10.1016/j.eururo.2024.03.037 | 16 | Robot-assisted |

The two Hospital de Clínic (Barcelona) studies describe consecutive, non-overlapping cohorts (1978–1987 and 1987–2009). Data for the historical cohort were taken from the updated analysis in Musquera et al. (2010).

## Key analytical decisions

- **Composite outcomes** (vascular and urinary complications) are counted **per patient**: each recipient contributes once per category regardless of the number of events.
- **1-year patient and graft survival:** direct counts for small series; for studies reporting only Kaplan–Meier estimates (both Hospital de Clínic cohorts and Medina), the number of 1-year survivors was back-calculated from the reported estimate and rounded to the nearest integer.
- **Delayed graft function** was not reported by either Hospital de Clínic cohort and is pooled from seven series (n = 57; Vigués denominator 15).
- Outcomes reported by only one or two series (e.g., urinary retention, urinary tract infection, deep-vein thrombosis) were not pooled.
- Full derivation of every number is given in `data/derivation_notes.csv`.
- `data/extraction_table.csv` is the raw extraction sheet (some free-text notes are in Portuguese). Where it differs from `data/study_event_counts.csv` (e.g., Medina transplantectomy: 3 per the article text), the event counts file and its derivation notes reflect the values actually analysed.

## Reproducing the analysis

Requirements: **R ≥ 4.6.0** with the packages `meta`, `metafor`, `dplyr`, `tidyr`, `ggplot2`, `openxlsx`, `stringr` and `purrr` (missing packages are installed automatically by the script).

```r
# set the working directory to the repository root, then:
source("code/OKT_meta_analysis.R")
```

The per-study event counts are defined at the top of the script (section 1) and mirror `data/study_event_counts.csv`. Results are written to `results/Meta_analysis_results.xlsx` and plots to `results/forest_plots/`. A random seed (`20260531`) is set for reproducibility.

## Licence

- Code (`code/`): MIT licence — see `LICENSE`.
- Data, results and supplementary files: CC BY 4.0 — see `LICENSE-data.md`.

All data are aggregate, study-level values extracted from published articles; no individual patient data are included. The source articles themselves are not redistributed here.

## Citation

Please cite the published article (details to be added) and this repository (see `CITATION.cff`; a Zenodo DOI will be added on release).

## Contact

Questions or corrections: please open an issue in this repository.
