# =====================================================================
# Orthotopic Kidney Transplantation — Systematic Review and Meta-analysis
#
# Pooled analyses of outcomes across the nine included case series
# (n = 265 recipients).
#
# Run from the repository root:  source("code/OKT_meta_analysis.R")
# Outputs are written to results/ (spreadsheet) and results/forest_plots/.
#
# Statistical approach
# --------------------
# Primary analysis:
#   Random-effects binomial generalised linear mixed model (GLMM) with
#   logit link, as implemented in meta::metaprop (which calls
#   metafor::rma.glmm). The between-study variance (tau^2) is estimated
#   jointly with the pooled effect by maximum likelihood within the GLMM
#   framework. Confidence intervals for the pooled estimate are adjusted
#   using the Hartung–Knapp–Sidik–Jonkman (HKSJ) method (t-distribution
#   with k–1 df), which improves coverage in meta-analyses with a small
#   number of studies. Continuity correction of 0.5/1 applied only to
#   studies with zero events or 100 % proportions.
#
# Robustness analyses:
#   (1) Leave-one-out (LOO) influence analysis for each outcome — re-
#       pools each outcome k times, dropping one study at a time, to
#       characterise per-study influence on the pooled estimate.
#   (2) Era meta-regression — tests whether each pooled proportion
#       varies systematically with publication year (1989–2024) using
#       a moderator model (metafor::rma.glmm with year as a continuous
#       moderator).
#
# Post hoc subgroup analysis:
#   (3) Surgical approach (open vs robot-assisted) — Vigués et al. is
#       the only robot-assisted series; the remaining 8 are open. The
#       subgroup analysis is therefore essentially a single-study
#       contrast for the robotic arm, but the framework is in place for
#       future updates as additional robotic series are published.
#
# Authors: Mendonça Rodrigues R, Costa Silva A, Pina Vaz T, Antunes-Lopes T,
#          Alturas Silva J
# Date:    May 2026
# =====================================================================

# ---------------------------------------------------------------------
# 0. Setup
# ---------------------------------------------------------------------
required <- c("meta", "metafor", "dplyr", "tidyr", "ggplot2",
              "openxlsx", "stringr", "purrr")
to_install <- setdiff(required, rownames(installed.packages()))
if (length(to_install)) install.packages(to_install,
                                         repos = "https://cloud.r-project.org")
invisible(lapply(required, library, character.only = TRUE))

set.seed(20260531)

out_dir <- file.path(getwd(), "results")
dir.create(out_dir, showWarnings = FALSE)
dir.create(file.path(out_dir, "forest_plots"), showWarnings = FALSE)


# ---------------------------------------------------------------------
# 1. Study-level data
# ---------------------------------------------------------------------
studies <- data.frame(
  study_id = c("Gil-Vernet (Historical HdC)", "Paduch", "Rodrigues",
               "De Gracia", "Musquera (Contemporary HdC)", "Chan",
               "Gutierrez-Zurimendi", "Medina", "Vigues"),
  year     = c(1989, 2001, 2004, 2007, 2010, 2018, 2021, 2022, 2024),
  n        = c(123, 5, 4, 6, 84, 3, 3, 21, 16),
  approach = c("Open", "Open", "Open", "Open", "Open", "Open",
               "Open", "Open", "Robot-assisted"),
  stringsAsFactors = FALSE
)

# Events per study (NA = outcome not assessed by that study)
events <- list(

  patient_survival_1y = c(116, 5,  4, 5, 76, 3,  3, 18, 15),
  graft_survival_1y   = c(109, 5,  4, 5, 73, 3,  3, 18, 14),

  dgf                 = c(NA, 1,  0, 2, NA, 1,  0,  8,  3),
  dgf_n               = c(NA, 5,  4, 6, NA, 3,  3, 21, 15),

  transplantectomy    = c( 6, 0,  0, 0,  5, 0,  0,  3,  1),

  # Vascular complications = number of patients with at least one vascular
  # event of any type (stenosis, thrombosis, severe vascular rejection,
  # intra-op low-flow / venous-return failure, post-op bleeding at a vascular
  # anastomosis). Per-patient, NOT per-event, so that overlap between event
  # types within the same patient is not double-counted. De Gracia: 5 patients
  # (5/6) had a vascular event — Cases 1,2,3,5,6 with stenosis; Cases 3 and 5
  # also bled but contribute only once to the per-patient count.
  vasc_overall        = c( 6, 1,  0, 5, 13, 1,  0,  4,  1),
  art_stenosis        = c( 4, 0,  0, 5,  3, 0,  0,  0,  0),
  art_thrombosis      = c( 0, 1,  0, 0,  4, 0,  0,  2,  1),
  ven_thrombosis      = c( 0, 0,  0, 0,  1, 0,  0,  0,  0),

  urin_overall        = c(10, 0,  0, 1, 11, 0,  0,  1,  2),
  urin_fistula        = c( 8, 0,  0, 0,  8, 0,  0,  1,  2),
  uret_obstruction    = c( 0, 0,  0, 1,  2, 0,  0,  0,  0),

  pancreatic_fistula  = c( 1, 0,  0, 0,  0, 0,  0,  1,  0),

  # Haemorrhagic complications — per-patient
  bleeding            = c( 0, 0,  0, 2,  0, 1,  0,  1,  0),

  # Urolithiasis (graft lithiasis) — Gil-Vernet 2 + Musquera 1 per Musquera 2010 Table 2
  urolithiasis        = c( 2, 0,  0, 0,  1, 0,  0,  0,  0),

  # Wound infection / surgical site infection — Chan Case 1 (Clavien II);
  # De Gracia Cases 1 and 4 (antibiotics); Medina early SSI (Clavien II).
  # Wound dehiscence (Chan Case 2) is a distinct mechanical event and not counted here.
  wound_infection     = c( 0, 0,  0, 2,  0, 1,  0,  1,  0),

  # Peri-graft fluid collection — Medina early-postop, Clavien II
  perigraft_fluid     = c( 0, 0,  0, 0,  0, 0,  0,  1,  0),

  # Lymphocele — Medina late obstructive lymphocele (Clavien IIIa); both
  # Hospital de Clínic cohorts explicitly report zero.
  lymphocele          = c( 0, 0,  0, 0,  0, 0,  0,  1,  0)
)


# ---------------------------------------------------------------------
# 2. Helper functions
# ---------------------------------------------------------------------
inv_logit <- function(x) {
  ifelse(is.na(x), NA_real_,
         ifelse(x ==  Inf, 1,
                ifelse(x == -Inf, 0, 1 / (1 + exp(-x)))))
}

# Run primary GLMM meta-analysis for one outcome
run_glmm <- function(label, k_vec, n_vec, study_labels) {
  keep <- !is.na(k_vec) & !is.na(n_vec)
  k <- k_vec[keep]; n <- n_vec[keep]; s <- study_labels[keep]

  m <- metaprop(event = k, n = n, studlab = s,
                sm = "PLOGIT",
                method = "GLMM",
                method.tau = "ML",
                method.random.ci = "HK",
                method.incr = "only0",
                incr = 0.5,
                prediction = TRUE)

  out <- data.frame(
    outcome      = label,
    k_studies    = length(k),
    events       = sum(k),
    total        = sum(n),
    pooled_pct   = round(100 * inv_logit(m$TE.random), 1),
    ci_lo_pct    = round(100 * inv_logit(m$lower.random), 1),
    ci_hi_pct    = round(100 * inv_logit(m$upper.random), 1),
    I2_pct       = round(m$I2 * 100, 0),
    tau2         = round(m$tau2, 3),
    pi_lo_pct    = round(100 * inv_logit(m$lower.predict), 1),
    pi_hi_pct    = round(100 * inv_logit(m$upper.predict), 1),
    stringsAsFactors = FALSE
  )
  attr(out, "meta") <- m
  out
}

# Save forest plot (meta::forest draws on a grid device, so use grid::grid.text
# rather than mtext for the title; reserve a top strip on the canvas).
save_forest <- function(meta_obj, filename, title) {
  png(filename = filename, width = 1400, height = 800,
      res = 130, type = "cairo")
  forest(meta_obj,
         studlab    = TRUE,
         common     = FALSE,
         random     = TRUE,
         prediction = TRUE,
         hetstat    = TRUE,
         leftcols   = c("studlab", "event", "n"),
         leftlabs   = c("Study", "Events", "Total"),
         rightcols  = c("effect", "ci"),
         rightlabs  = c("Proportion", "95 % CI"),
         digits = 3, digits.tau2 = 3,
         col.diamond = "#1F4E79",
         col.predict = "#FF9933",
         print.tau2  = TRUE,
         fontsize = 10)
  # Title overlay via the grid device that meta::forest uses
  grid::grid.text(title,
                  x = grid::unit(0.5, "npc"),
                  y = grid::unit(0.97, "npc"),
                  gp = grid::gpar(fontsize = 14, fontface = "bold",
                                  col = "#1F2937"))
  dev.off()
}


# ---------------------------------------------------------------------
# 3. Outcome configuration
# ---------------------------------------------------------------------
outcomes <- list(
  list(label = "Patient survival at 1 year",       key = "patient_survival_1y", n_use = "default"),
  list(label = "Graft survival at 1 year",         key = "graft_survival_1y",   n_use = "default"),
  list(label = "Delayed graft function",           key = "dgf",                 n_use = "dgf_n"),
  list(label = "Transplantectomy",                 key = "transplantectomy",    n_use = "default"),
  list(label = "Vascular complications (overall)", key = "vasc_overall",        n_use = "default"),
  list(label = "Arterial stenosis",                key = "art_stenosis",        n_use = "default"),
  list(label = "Arterial thrombosis",              key = "art_thrombosis",      n_use = "default"),
  list(label = "Venous thrombosis",                key = "ven_thrombosis",      n_use = "default"),
  list(label = "Urinary complications (overall)",  key = "urin_overall",        n_use = "default"),
  list(label = "Urinary fistula",                  key = "urin_fistula",        n_use = "default"),
  list(label = "Ureteric obstruction",             key = "uret_obstruction",    n_use = "default"),
  list(label = "Pancreatic fistula",               key = "pancreatic_fistula",  n_use = "default"),
  list(label = "Haemorrhagic complications",       key = "bleeding",            n_use = "default"),
  list(label = "Urolithiasis",                     key = "urolithiasis",        n_use = "default"),
  list(label = "Wound infection",                  key = "wound_infection",     n_use = "default"),
  list(label = "Peri-graft fluid collection",      key = "perigraft_fluid",     n_use = "default"),
  list(label = "Lymphocele",                       key = "lymphocele",          n_use = "default")
)


# ---------------------------------------------------------------------
# 4. Primary analysis — GLMM for all 12 outcomes
# ---------------------------------------------------------------------
primary_results <- purrr::map_dfr(outcomes, function(o) {
  k_vec <- events[[o$key]]
  n_vec <- if (o$n_use == "default") studies$n else events[[o$n_use]]
  result <- run_glmm(o$label, k_vec, n_vec, studies$study_id)
  safe_name <- str_replace_all(o$label, "[^A-Za-z0-9]+", "_")
  save_forest(attr(result, "meta"),
              file.path(out_dir, "forest_plots",
                        paste0("Primary_", safe_name, ".png")),
              title = paste0(o$label, " — Primary analysis (GLMM, HKSJ)"))
  result
})

cat("\n=== Primary analysis (binomial GLMM, HKSJ CI) ===\n")
print(primary_results)


# ---------------------------------------------------------------------
# 5. Robustness analysis (a) — Leave-one-out (LOO) influence
# ---------------------------------------------------------------------
# For each outcome, re-pool k times, dropping one study at a time.
# A LOO estimate that differs substantially from the full pooled
# estimate identifies an outsized single-study influence on the pool.

run_loo <- function(label, k_vec, n_vec, study_labels) {
  keep <- !is.na(k_vec) & !is.na(n_vec)
  k <- k_vec[keep]; n <- n_vec[keep]; s <- study_labels[keep]

  # Full pooled estimate (all studies)
  m_all <- tryCatch(metaprop(event = k, n = n, studlab = s,
                             sm = "PLOGIT", method = "GLMM",
                             method.tau = "ML", method.random.ci = "HK",
                             method.incr = "only0", incr = 0.5),
                    error = function(e) NULL)
  if (is.null(m_all)) return(tibble())

  out <- tibble(
    outcome = label,
    omitted_study = "(none — pooled with all studies)",
    pooled_pct  = round(100 * inv_logit(m_all$TE.random), 1),
    ci_lo_pct   = round(100 * inv_logit(m_all$lower.random), 1),
    ci_hi_pct   = round(100 * inv_logit(m_all$upper.random), 1),
    I2_pct      = round(m_all$I2 * 100, 0)
  )

  for (i in seq_along(s)) {
    m_loo <- tryCatch(metaprop(event = k[-i], n = n[-i], studlab = s[-i],
                               sm = "PLOGIT", method = "GLMM",
                               method.tau = "ML", method.random.ci = "HK",
                               method.incr = "only0", incr = 0.5),
                      error = function(e) NULL)
    if (!is.null(m_loo)) {
      out <- bind_rows(out, tibble(
        outcome = label,
        omitted_study = s[i],
        pooled_pct = round(100 * inv_logit(m_loo$TE.random), 1),
        ci_lo_pct  = round(100 * inv_logit(m_loo$lower.random), 1),
        ci_hi_pct  = round(100 * inv_logit(m_loo$upper.random), 1),
        I2_pct     = round(m_loo$I2 * 100, 0)
      ))
    } else {
      out <- bind_rows(out, tibble(
        outcome = label, omitted_study = s[i],
        pooled_pct = NA, ci_lo_pct = NA, ci_hi_pct = NA, I2_pct = NA
      ))
    }
  }
  out
}

loo_results <- purrr::map_dfr(outcomes, function(o) {
  k_vec <- events[[o$key]]
  n_vec <- if (o$n_use == "default") studies$n else events[[o$n_use]]
  run_loo(o$label, k_vec, n_vec, studies$study_id)
})

cat("\n=== Robustness 1: Leave-one-out influence analysis ===\n")
print(loo_results)


# ---------------------------------------------------------------------
# 6. Robustness analysis (b) — Era meta-regression
# ---------------------------------------------------------------------
# Tests whether each pooled proportion varies with publication year
# (1989–2024) via a continuous moderator in a binomial GLMM. Reports
# the slope on the logit scale (per +1 year), its 95 % CI, and the
# Wald p-value for the moderator. Models requiring < 3 informative
# studies are not fitted.

run_era_regression <- function(label, k_vec, n_vec, study_labels, study_years) {
  keep <- !is.na(k_vec) & !is.na(n_vec)
  k <- k_vec[keep]; n <- n_vec[keep]; y <- study_years[keep]
  if (length(k) < 3) {
    return(tibble(outcome = label, k_studies = length(k),
                  beta_logit = NA, se_logit = NA,
                  ci_lo_logit = NA, ci_hi_logit = NA,
                  p_value = NA,
                  notes = "k < 3 — model not fitted"))
  }
  fit <- tryCatch(
    metafor::rma.glmm(xi = k, ni = n, measure = "PLO",
                      mods = ~ y, method = "ML"),
    error = function(e) NULL
  )
  if (is.null(fit)) {
    return(tibble(outcome = label, k_studies = length(k),
                  beta_logit = NA, se_logit = NA,
                  ci_lo_logit = NA, ci_hi_logit = NA,
                  p_value = NA,
                  notes = "model failed to converge"))
  }
  tibble(
    outcome     = label,
    k_studies   = length(k),
    beta_logit  = round(as.numeric(coef(fit)["y"]), 4),
    se_logit    = round(fit$se[2], 4),
    ci_lo_logit = round(fit$ci.lb[2], 4),
    ci_hi_logit = round(fit$ci.ub[2], 4),
    p_value     = round(fit$pval[2], 3),
    notes       = ifelse(fit$pval[2] < 0.05,
                         "significant time trend", "no significant time trend")
  )
}

era_regression <- purrr::map_dfr(outcomes, function(o) {
  k_vec <- events[[o$key]]
  n_vec <- if (o$n_use == "default") studies$n else events[[o$n_use]]
  run_era_regression(o$label, k_vec, n_vec, studies$study_id, studies$year)
})

cat("\n=== Robustness 2: Era meta-regression (year as moderator) ===\n")
print(era_regression)


# ---------------------------------------------------------------------
# 7. Subgroup analysis — surgical approach (open vs robot-assisted)
# ---------------------------------------------------------------------
# 8 open series + 1 robot-assisted (Vigues). The robotic subgroup is a
# single-study contrast; the framework is in place for future updates.

run_subgroup <- function(label, k_vec, n_vec, study_labels, approach) {
  keep <- !is.na(k_vec) & !is.na(n_vec)
  k <- k_vec[keep]; n <- n_vec[keep]; s <- study_labels[keep]; a <- approach[keep]

  m <- tryCatch(
    metaprop(event = k, n = n, studlab = s,
             sm = "PLOGIT", method = "GLMM",
             method.tau = "ML", method.random.ci = "HK",
             method.incr = "only0", incr = 0.5,
             subgroup = a, tau.common = FALSE),
    error = function(e) NULL
  )
  if (is.null(m)) return(tibble())

  out <- tibble()
  for (i in seq_along(m$bylevs)) {
    out <- bind_rows(out, tibble(
      outcome    = label,
      subgroup   = m$bylevs[i],
      k_studies  = m$k.w[i],
      events     = m$event.w[i],
      total      = m$n.w[i],
      pooled_pct = round(100 * inv_logit(m$TE.random.w[i]), 1),
      ci_lo_pct  = round(100 * inv_logit(m$lower.random.w[i]), 1),
      ci_hi_pct  = round(100 * inv_logit(m$upper.random.w[i]), 1),
      I2_pct     = round(m$I2.w[i] * 100, 0),
      p_subgroup_diff = round(m$pval.Q.b.random, 3)
    ))
  }
  out
}

subgroup_results <- purrr::map_dfr(outcomes, function(o) {
  k_vec <- events[[o$key]]
  n_vec <- if (o$n_use == "default") studies$n else events[[o$n_use]]
  run_subgroup(o$label, k_vec, n_vec, studies$study_id, studies$approach)
})

cat("\n=== Subgroup analysis: open vs robot-assisted ===\n")
print(subgroup_results)


# ---------------------------------------------------------------------
# 8. Save all results to one Excel workbook
# ---------------------------------------------------------------------
wb <- createWorkbook()

addWorksheet(wb, "Primary analysis (GLMM)")
writeData(wb, "Primary analysis (GLMM)", primary_results)

addWorksheet(wb, "LOO influence")
writeData(wb, "LOO influence", loo_results)

addWorksheet(wb, "Era meta-regression")
writeData(wb, "Era meta-regression", era_regression)

addWorksheet(wb, "Subgroup open vs robotic")
writeData(wb, "Subgroup open vs robotic", subgroup_results)

saveWorkbook(wb,
             file.path(out_dir, "Meta_analysis_results.xlsx"),
             overwrite = TRUE)

cat("\n--- Meta-analysis complete. ---\n",
    "Results spreadsheet: ", file.path(out_dir, "Meta_analysis_results.xlsx"), "\n",
    "Forest plots:        ", file.path(out_dir, "forest_plots"), "\n", sep = "")
