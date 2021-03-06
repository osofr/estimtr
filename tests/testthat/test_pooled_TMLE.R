context("Fitting with no Monitoring and / or no Censoring indicators")

  ## -----------------------------------------------------------------------
  ## Analyses by intervention
  ## **** makes it easier to read the individual analyses ****
  ## -----------------------------------------------------------------------
  `%+%` <- function(a, b) paste0(a, b)
  library("stremr")
  options(stremr.verbose = FALSE)
  options(gridisl.verbose = FALSE)
  options(sl3.verbose = FALSE)
  # options(stremr.verbose = TRUE)
  # options(gridisl.verbose = TRUE)
  # options(sl3.verbose = TRUE)
  library("data.table")
  library("magrittr")
  library("ggplot2")
  library("tibble")
  library("tidyr")
  library("purrr")
  library("dplyr")

  data(OdatDT_10K)
  Odat_DT <- OdatDT_10K
  # select only the first 100 IDs
  Odat_DT <- Odat_DT[ID %in% (1:500), ]
  setkeyv(Odat_DT, cols = c("ID", "t"))

  ## -----------------------------------------------------------------------
  ## Define some summaries (lags C[t-1], A[t-1], N[t-1])
  ## -----------------------------------------------------------------------
  ID <- "ID"; t <- "t"; TRT <- "TI"; I <- "highA1c"; outcome <- "Y.tplus1";
  lagnodes <- c("C", "TI", "N")
  newVarnames <- paste0(lagnodes, ".tminus1")
  Odat_DT[, (newVarnames) := shift(.SD, n=1L, fill=0L, type="lag"), by=ID, .SDcols=(lagnodes)]
  # indicator that the person has never been on treatment up to current t
  Odat_DT[, ("barTIm1eq0") := as.integer(c(0, cumsum(get(TRT))[-.N]) %in% 0), by = eval(ID)]
  Odat_DT[, ("lastNat1.factor") := as.factor(lastNat1)]

  ## remove indicators of censoring and monitoring events:
  Odat_DT[, "N" := NULL]
  Odat_DT[, "C" := NULL]

  ## ------------------------------------------------------------------
  ## Propensity score models for Treatment, Censoring & Monitoring
  ## ------------------------------------------------------------------
  gform_TRT <- "TI ~ CVD + highA1c + N.tminus1"
  stratify_TRT <- list(
    TI=c("t == 0L",                                            # MODEL TI AT t=0
         "(t > 0L) & (N.tminus1 == 1L) & (barTIm1eq0 == 1L)",  # MODEL TRT INITATION WHEN MONITORED
         "(t > 0L) & (N.tminus1 == 0L) & (barTIm1eq0 == 1L)",  # MODEL TRT INITATION WHEN NOT MONITORED
         "(t > 0L) & (barTIm1eq0 == 0L)"                       # MODEL TRT CONTINUATION (BOTH MONITORED AND NOT MONITORED)
        ))

  ## ------------------------------------------------------------
  ## **** As a first step define a grid of all possible parameter combinations (for all estimators)
  ## **** This dataset is to be saved and will be later merged in with all analysis
  ## ------------------------------------------------------------
  # tvals <- 0:2
  tvals <- 10
  tmax <- 13
  tbreaks = c(1:8,11,14)-1

  ## This dataset defines all parameters that we like to vary in this analysis (including different interventions)
  ## That is, each row of this dataset corresponds with a single analysis, for one intervention of interest.
  # analysis <- list(intervened_TRT = c("gTI.dlow", "gTI.dhigh"),
  #                 stratifyQ_by_rule = c(TRUE)) %>%
  #                 cross_d() %>%
  #                 arrange(stratifyQ_by_rule)

  ## ------------------------------------------------------------------------
  ## Define models for fitting propensity scores (g) -- PARAMETRIC LOGISTIC REGRESSION
  ## ------------------------------------------------------------------------
  fit_method_g <- "none"
  # models_g <- defModel(estimator = "speedglm__glm", family = "quasibinomial")
  models_g <- Lrnr_glm_fast$new()

  ## ------------------------------------------------------------------------
  ## Define models for iterative G-COMP (Q) -- PARAMETRIC LOGISTIC REGRESSION
  ## ------------------------------------------------------------------------
  ## regression formulas for Q's:
  Qforms <- rep.int("Qkplus1 ~ CVD + highA1c + lastNat1 + TI + TI.tminus1", (max(tvals)+1))
  ## no cross-validation model selection, just fit a single model specified below
  fit_method_Q <- "none"
  ## Use speedglm to fit all Q.
  ## NOTE: it is currently not possible to use fit_method_Q <- "cv" with speedglm or glm.
  ## To perform cross-validation with GLM use 'estimator="h2o__glm"' or 'estimator="xgboost__glm"'
  # models_Q <- defModel(estimator = "speedglm__glm", family = "quasibinomial")
  # models_Q <- defModel(estimator = "xgboost__glm", family = "quasibinomial")
  # models_Q <- defModel(estimator = "xgboost__glm", family = "quasibinomial", nrounds = 50, objective = "reg:logistic")
  # models_Q <- defModel(estimator = "xgboost__gbm", family = "quasibinomial", nrounds = 50, objective = "reg:logistic")
  models_Q <- Lrnr_xgboost$new(nrounds = 10, objective = "reg:logistic")
  ## ----------------------------------------------------------------
  ## Fit propensity score models.
  ## We are using the same model ensemble defined in models_g for censoring, treatment and monitoring mechanisms.
  ## ----------------------------------------------------------------
  OData <- stremr::importData(Odat_DT, ID = "ID", t = "t", covars = c("highA1c", "lastNat1", "lastNat1.factor"), TRT = "TI", OUTCOME = "Y.tplus1")
  OData <- fitPropensity(OData,
                          gform_TRT = gform_TRT,
                          stratify_TRT = stratify_TRT,
                          models_TRT = models_g,
                          fit_method = fit_method_g
                          )

  test_that("GCOMP pooling works", {
    # delta <- 0.35
    # pooledGCOMP <- fit_pooled_GCOMP(OData = OData,
    #                                      intervened_TRT = c("gTI.dlow", "gTI.dhigh"),
    #                                      stratifyQ_by_rule = TRUE,
    #                                      tvals = tvals,
    #                                      models = models_Q,
    #                                      Qforms = Qforms,
    #                                      fit_method = fit_method_Q,
    #                                      maxpY = delta)


    delta <- 1
    pooledGCOMP_2 <- fit_pooled_GCOMP(OData = OData,
                                         intervened_TRT = c("gTI.dlow", "gTI.dhigh"),
                                         stratifyQ_by_rule = TRUE,
                                         tvals = tvals,
                                         models = models_Q,
                                         Qforms = Qforms,
                                         fit_method = fit_method_Q,
                                         maxpY = delta)
  })

  test_that("TMLE pooling works", {
    # delta <- 0.35
    # pooledTMLE <- fit_pooled_TMLE(OData = OData,
    #                               intervened_TRT = c("gTI.dlow", "gTI.dhigh"),
    #                               stratifyQ_by_rule = TRUE,
    #                               tvals = tvals,
    #                               models = models_Q,
    #                               Qforms = Qforms,
    #                               fit_method = fit_method_Q,
    #                               maxpY = delta,
    #                               TMLE_updater = "iTMLE.updater.xgb")

    delta <- 1
    pooledTMLE_2 <- fit_pooled_TMLE(OData = OData,
                                  intervened_TRT = c("gTI.dlow", "gTI.dhigh"),
                                  stratifyQ_by_rule = TRUE,
                                  tvals = tvals,
                                  models = models_Q,
                                  Qforms = Qforms,
                                  fit_method = fit_method_Q,
                                  maxpY = delta)
  })
