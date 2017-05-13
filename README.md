stremr
==========

[![CRAN_Status_Badge](http://www.r-pkg.org/badges/version/stremr)](https://CRAN.R-project.org/package=stremr)
[![](https://cranlogs.r-pkg.org/badges/stremr)](https://CRAN.R-project.org/package=stremr)
[![Travis-CI Build Status](https://travis-ci.org/osofr/stremr.svg?branch=master)](https://travis-ci.org/osofr/stremr)
[![Coverage Status](https://coveralls.io/repos/github/osofr/stremr/badge.svg)](https://coveralls.io/github/osofr/stremr)

Analysis of longitudinal data, with continuous or time-to-event (binary) outcome.
The package implements several estimators of the expected counterfactual outcome under static, dynamic or stochastic interventions over multiple time-points. Adjusts for *measured* time-varying confounding and informative right-censoring.

Currently available estimators can be roughly categorized into 4 groups:

  * Propensity-score / Inverse Probability Weighted (IPW):
    - direct (bounded) IPW ('directIPW')
    - [IPW-adjusted Kaplan-Meier](https://doi.org/10.1002/sim.2174) (`survNPMSM`)
    - [MSM-IPW for the survival hazard](https://doi.org/10.1016/j.jclinepi.2013.01.016) (`survMSM`)
  * Outcome regression:
    - longitudinal G-formula `GCOMP` ([Bang and Robins, 2005](https://doi.org/10.1111/j.1541-0420.2005.00377.x))
  * Doubly-robust (DR) approaches:
    - longitudinal long format `TMLE` ([van der Laan and Gruber, 2012](http://biostats.bepress.com/ucbbiostat/paper290/))
    - iterative longitudinal TMLE (`iterTMLE`)
    - longitudinal cross-validated TMLE (`CVTMLE`)
  * Sequentially doubly-robust (SDR) approaches:
    - infinite-dimensional TMLE (`iTMLE`) ([Luedtke et al., 2017](https://arxiv.org/abs/1705.02459))
    - doubly robust unbiased transformations (`DR transform`) ([Rubin and van der Laan, 2006](http://biostats.bepress.com/ucbbiostat/paper208), [Luedtke et al., 2017](https://arxiv.org/abs/1705.02459))

**Input data**: 

The exposure, monitoring and censoring variables can be coded as either binary, categorical or continuous. Each can be multivariate (e.g., can use more than one column of dummy indicators for different censoring events). The input data needs to be in long format.

 - Possibly right-censored data has to be in long format.
 - Each row must contain a subject identifier (`ID`) and the integer indicator of the current time (`t`), e.g., day, week, month, year.
 - The package assumes that the temporal ordering of covariates in each row is **fixed** according to (`ID`, `t`, `L`,`C`,`A`,`N`,`Y`), where 
     * `L` -- Time-varying and baseline covariates.
     * `C` -- Indicators of right censoring events at time `t`; this can be either a single categorical or several binary columns.
     * `A` -- Exposure (treatment) at time `t`; this can be multivariate (more than one column) and each column can be binary, categorical or continuous.
     * `N` -- Indicator of being monitored at time point `t+1` (binary).
     * `Y` -- Outcome (binary 0/1 or continuous between 0 and 1).
 - Categorical censoring can be useful for representing all of the censoring events with a single column (variable).

**Model fitting:**
 - Separate models are fit for the observed censoring, exposure and monitoring mechanisms.
 - Each model can be stratified (separate model is fit) by time or any other user-specified stratification criteria. Each strata is defined with by a single logical expression that selects specific observations/rows in the observed data (strata).
 -  By default, all models are fit using `GLM` with `binomial` family (logistic regression). 
 -  Alternatively, model fitting can be also performed with any machine learning algorithm implemented in `h2o` or `xgboost` R packages
 -  One can select the best model from an ensemble of many learners by using cross-validation (supported by `gridisl` R package).

**Overview**:
* [Installing `stremr` and Documentation](#Installation)
* [Automated Reports](#Reports)
* [Example with Simulated Data](#Example1)
* [Sequential G-Computation (GCOMP) and Targeted Maximum Likelihood Estimation (TMLE) for longitudinal survival data](#GCOMPTMLE)
* [Machine Learning](#ML)
* [Ensemble Learning with Discrete SuperLearner (based on `gridisl` R package)](#gridisl)

<a name="Installation"></a>
### Installation and Documentation

<!-- To install the CRAN release version of `stremr`: 
```R
install.packages('stremr')
```
 -->

To install the development version (requires the `devtools` package):

```R
devtools::install_github('osofr/stremr')
```

For ensemble learning with SuperLearner we recommend installing the latest development version of the `gridisl` R package:

```R
devtools::install_github('osofr/gridisl')
```

For optimal performance, we also recommend installing the latest version of `data.table` package:
```R
remove.packages("data.table")                         # First remove the current version
install.packages("data.table", type = "source",
    repos = "http://Rdatatable.github.io/data.table") # Then install devel version
```

<!-- For specific documentation on how to run `stremr()` function:
```R
?stremr
```
 -->

To obtain documentation for specific relevant functions in `stremr` package:
```R
?importData
?fitPropensity
?getIPWeights
?directIPW
?survNPMSM
?survMSM
?fitGCOMP
?fitTMLE
?fit_iTMLE
?fit_iterTMLE
```

<!-- <a name="Reports"></a>
### Automated Reports:

The following is an example of a function call that produces an automated `html` report shown below. For a pdf report just set the argument `format = "pdf"`.
```R
  make_report_rmd(OData, NPMSM = list(surv1, surv2), 
                  MSM = MSM.IPAW, 
                  GCOMP = list(gcomp_est1, gcomp_est2), 
                  TMLE = list(tmle_est_par1, tmle_est_par2),
                  AddFUPtables = TRUE, RDtables = get_MSM_RDs(MSM.IPAW, t.periods.RDs = c(12, 15), getSEs = TRUE),
                  WTtables = get_wtsummary(MSM.IPAW$wts_data, cutoffs = c(0, 0.5, 1, 10, 20, 30, 40, 50, 100, 150), by.rule = TRUE),
                  file.name = "sim.data.example.fup", title = "Custom Report Title", author = "Author Name", y_legend = 0.99, x_legend = 9.5)
```

![gif](https://cloud.githubusercontent.com/assets/6721358/18609476/d9b4db74-7cb7-11e6-9ca6-aacf0b70ca4c.gif)

 -->

<a name="Example1"></a>
### Example with Simulated Data

Load the data:

```R
require("stremr")
require("data.table")
data(OdataNoCENS)
OdataDT <- as.data.table(OdataNoCENS, key=c(ID, t))
```

Define some summaries (lags):
```R
OdataDT[, ("N.tminus1") := shift(get("N"), n = 1L, type = "lag", fill = 1L), by = ID]
OdataDT[, ("TI.tminus1") := shift(get("TI"), n = 1L, type = "lag", fill = 1L), by = ID]
```

Import input data into `stremr` object `DataStorageClass` and define relevant covariates:
```R
OData <- importData(OdataDT, ID = "ID", t = "t", covars = c("highA1c", "lastNat1", "N.tminus1"), CENS = "C", TRT = "TI", MONITOR = "N", OUTCOME = "Y.tplus1")
```

Define counterfactual exposures. In this example we define one intervention as always treated  and another as never treated. Such intervention can be defined conditionally on other variables (dynamic intervention). Similarly, one can define the intervention as a probability that the counterfactual exposure is 1 at each time-point `t` (for stochastic interventions).
```R
OdataDT[, ("TI.set1") := 1L]
OdataDT[, ("TI.set0") := 0L]
```

Regressions for modeling the propensity scores for censoring (`CENS`), exposure (`TRT`) and monitoring (`MONITOR`). By default, each of these propensity scores is fit with a common model that pools across all available time points (smoothing over time).
```R
gform_CENS <- "C + TI + N ~ highA1c + lastNat1"
gform_TRT <- "TI ~ CVD + highA1c + N.tminus1"
gform_MONITOR <- "N ~ 1"
```

Stratification, that is, fitting separate models for different time-points, is enabled with logical expressions in arguments `stratify_...` (see `?fitPropensity`). For example, the logical expression below states that we want to fit the censoring mechanism with a separate model for time point 16, while pooling with a common model fit over time-points 0 to 15. Any logical expression can be used to define such stratified modeling. This can be similarly applied to modeling the exposure mechanism (`stratify_TRT`) and the monitoring mechanism (`stratify_MONITOR`).
```R
stratify_CENS <- list(C=c("t < 16", "t == 16"))
```

Fit the propensity scores for censoring, exposure and monitoring:
```R
OData <- fitPropensity(OData, gform_CENS = gform_CENS, gform_TRT = gform_TRT, gform_MONITOR = gform_MONITOR, stratify_CENS = stratify_CENS)
```

<a name="survNPMSM"></a>Estimate survival based on non-parametric MSM (IPTW-ADJUSTED KM):
```R
require("magrittr")
AKME.St.1 <- getIPWeights(OData, intervened_TRT = "TI.set1") %>%
             survNPMSM(OData) %$%
             estimates
AKME.St.1
```

<a name="directIPW"></a>Estimate survival with bounded IPW:
```R
IPW.St.1 <- getIPWeights(OData, intervened_TRT = "TI.set1") %>%
            directIPW(OData)
IPW.St.1[]
```

<a name="survMSM"></a>Estimate hazard with IPW-MSM then map into survival estimate. Using two regimens and smoothing over two intervals of time-points:
```R
wts.DT.1 <- getIPWeights(OData = OData, intervened_TRT = "TI.set1", rule_name = "TI1")
wts.DT.0 <- getIPWeights(OData = OData, intervened_TRT = "TI.set0", rule_name = "TI0")
survMSM_res <- survMSM(list(wts.DT.1, wts.DT.0), OData, tbreaks = c(1:8,12,16)-1,)
survMSM_res$St
```

<a name="GCOMPTMLE"></a>
### Longitudinal GCOMP (G-formula) and TMLE.

Define time-points of interest, regression formulas and software to be used for fitting the sequential outcome models:
```R
t.surv <- c(0:15)
Qforms <- rep.int("Qkplus1 ~ CVD + highA1c + N + lastNat1 + TI + TI.tminus1", (max(t.surv)+1))
params = list(fit.package = "speedglm", fit.algorithm = "glm")
```

G-Computation (pooled):
```R
gcomp_est <- fitGCOMP(OData, tvals = t.surv, intervened_TRT = "TI.set1", Qforms = Qforms, models = params, stratifyQ_by_rule = FALSE)
```

Targeted Maximum Likelihood Estimation (TMLE) (stratified):
```R
tmle_est <- fitTMLE(OData, tvals = t.surv, intervened_TRT = "TI.set1", Qforms = Qforms, models = params, stratifyQ_by_rule = TRUE)
tmle_est[]
```

To parallelize estimation over several time-points (`t.surv`) for either GCOMP or TMLE use argument `parallel = TRUE`:
```R
require("doParallel")
registerDoParallel(cores = 40)
data.table::setthreads(1)
tmle_est <- fitTMLE(OData, tvals = t.surv, intervened_TRT = "TI.set1", Qforms = Qforms, models = params, stratifyQ_by_rule = TRUE, parallel = TRUE)
```

<a name="ML"></a>
### Data-adaptive estimation, machine-learning and cross-validation

Nuisance parameters can be modeled with machine learning R packages `xgboost` and `h2o` (*GLM*, *Regularized GLM* *Distributed Random Forest (RF)*, *Extreme Gradient Boosting (GBM)*, *Deep Neural Nets*). The package provides simple syntax for specifying large grids of tuning parameters, including random grid search over parameter space. Model selection can be performed via V-fold cross-validation or random validation splits.

For less error-prone fitting with `h2o` (especially if using `estimator="h2o__glm"`, please install this version of `h2o` R package:

```R
if ("package:h2o" %in% search()) { detach("package:h2o", unload=TRUE) }
if ("h2o" %in% rownames(installed.packages())) { remove.packages("h2o") }
# Next, we download packages that H2O depends on.
if (! ("methods" %in% rownames(installed.packages()))) { install.packages("methods") }
if (! ("statmod" %in% rownames(installed.packages()))) { install.packages("statmod") }
if (! ("stats" %in% rownames(installed.packages()))) { install.packages("stats") }
if (! ("graphics" %in% rownames(installed.packages()))) { install.packages("graphics") }
if (! ("RCurl" %in% rownames(installed.packages()))) { install.packages("RCurl") }
if (! ("jsonlite" %in% rownames(installed.packages()))) { install.packages("jsonlite") }
if (! ("tools" %in% rownames(installed.packages()))) { install.packages("tools") }
if (! ("utils" %in% rownames(installed.packages()))) { install.packages("utils") }
# Now we download, install and initialize the H2O package for R.
install.packages("h2o", type="source", repos=(c("http://h2o-release.s3.amazonaws.com/h2o/rel-tutte/2/R")))
```

To set-up `stremr` so that it performs any model fitting with distributed Random Forest just set the global options `estimator = "h2o__randomForest"`:
```R
set_all_stremr_options(estimator = "h2o__randomForest")

require("h2o")
h2o::h2o.init(nthreads = -1)

OData <- fitPropensity(OData, gform_CENS = gform_CENS, gform_TRT = gform_TRT, gform_MONITOR = gform_MONITOR, stratify_CENS = stratify_CENS)
```

Other available algorithms are Gradient Boosting Machines (`estimator = "h2o__gbm"`) or Extreme Gradient Boosting (`estimator = "xgboost__gbm"`), distributed GLM (including LASSO and Ridge) (`estimator = "h2o__glm"` or `estimator = "xgboost__glm"`) and Deep Neural Nets (`estimator = "h2o__deeplearning"`).

<!-- Use arguments `params_...` in `fitPropensity()` and `models` in `fitGCOMP()` and `fitTMLE()` to pass various tuning parameters and select different algorithms for different models:
```R
params_TRT = list(fit.package = "h2o", fit.algorithm = "gbm", ntrees = 50, learn_rate = 0.05, sample_rate = 0.8, col_sample_rate = 0.8, balance_classes = TRUE)
params_CENS = list(fit.package = "speedglm", fit.algorithm = "glm")
params_MONITOR = list(fit.package = "speedglm", fit.algorithm = "glm")
OData <- fitPropensity(OData,
          gform_CENS = gform_CENS, stratify_CENS = stratify_CENS, params_CENS = params_CENS,
          gform_TRT = gform_TRT, params_TRT = params_TRT,
          gform_MONITOR = gform_MONITOR, params_MONITOR = params_MONITOR)
```
 -->
 
<!-- Running TMLE based on the previous fit of the propensity scores. Also applying Random Forest to estimate the sequential outcome model:
```R
models = list(fit.package = "h2o", fit.algorithm = "randomForest", ntrees = 100, learn_rate = 0.05, sample_rate = 0.8, col_sample_rate = 0.8, balance_classes = TRUE)

tmle_est <- fitTMLE(OData, tvals = t.surv, intervened_TRT = "TI.set1", Qforms = Qforms, models = models, stratifyQ_by_rule = TRUE)
```
 -->
<!-- <a name="SuperLearner"></a>
###Ensemble Learning with SuperLearner (based on `gridisl` R package)

```R
require('gridisl')
```


Easy specification of large ensembles with grid search:

1. Define a learning algorithm (e.g., `glm`)
2. Define the search criteria (e.g., 120 second maximum). Increase parameters `max_runtime_secs` or `max_models` to cover larger number of models from tuning parameter space.
3. Define the space of tuning parameters (hyper-parameters) by specifying their learner-specific names and values for grid search (e.g., `alpha` and `lambda` for glm).


When running the SuperLearner with grid search, `stremr` calls the following outside functions:

1. Runs `h2o.grid` in the background for each individual learner and saves cross-validated risks.
2. Calls `h2o.stack` from `h2oEnsemble` package to evaluate the final SuperLearner fit on a combination of all learners returned by different grid searches and individually specified learners.


Here is an example defining the grid search criteria and search space of tuning parameters for h2o glm (`h2o.glm`):
```R
GLM_hyper_params <- list(search_criteria = list(strategy = "RandomDiscrete", max_models = 5),
                         alpha = c(0,1,seq(0.1,0.9,0.1)),
                         lambda = c(0,1e-7,1e-5,1e-3,1e-1))
```

Another example with grid search for Random Forest (`h2o.randomForest`) (will be combined with above in a single SuperLearner ensemble):
```R
search_criteria <- list(strategy = "RandomDiscrete", max_models = 5, max_runtime_secs = 60*60)
RF_hyper_params <- list(search_criteria = search_criteria,
                        ntrees = c(100, 200, 300, 500),
                        mtries = 1:4,
                        max_depth = c(5, 10, 15, 20, 25),
                        sample_rate = c(0.7, 0.8, 0.9, 1.0),
                        col_sample_rate_per_tree = c(0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8),
                        balance_classes = c(TRUE, FALSE))
```

Final example with grid search for Gradient Boosting Machines (`h2o.gbm`) (will be also combined with above grid searches):
```R
GBM_hyper_params <- list(search_criteria = search_criteria,
                         ntrees = c(100, 200, 300, 500),
                         learn_rate = c(0.005, 0.01, 0.03, 0.06),
                         max_depth = c(3, 4, 5, 6, 9),
                         sample_rate = c(0.7, 0.8, 0.9, 1.0),
                         col_sample_rate = c(0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8),
                         balance_classes = c(TRUE, FALSE))
```

In addition, we can specify individual learners that we may want to include in the SuperLearner library:
```R
h2o.glm.1 <- function(..., alpha = 0.0) h2o.glm.wrapper(..., alpha = alpha)
h2o.glm.2 <- function(..., x = "highA1c", alpha = 0.0) h2o.glm.wrapper(..., x = x, alpha = alpha)
h2o.glm.3 <- function(..., alpha = 1.0) h2o.glm.wrapper(..., alpha = alpha)
```

The SuperLearner ensemble is now defined with a single list of parameters that includes the above models.  We also define additional SuperLearner-specific parameters here (such as, `nfolds` - number of folds for cross-validation, `metalearner` and `seed`):
```R
SLparams = list(fit.package = "h2o", fit.algorithm = "SuperLearner",
                 grid.algorithm = c("glm", "randomForest", "gbm"),
                 learner = c("h2o.glm.1", "h2o.glm.2", "h2o.glm.3"),
                 metalearner = "h2o.glm_nn",
                 nfolds = 10,
                 seed = 23,
                 glm = GLM_hyper_params,
                 randomForest = RF_hyper_params,
                 gbm = GBM_hyper_params)
```


We can also save the SuperLearner fits by adding parameters `save.ensemble` and `ensemble.dir.path`. This will save the entire ensemble of models that were used by the SuperLearner. Separate directories are required for different SuperLearner models (for example a separate directory for censoring model and a separate directory for treatment model). These pre-saved fits can be loaded at a later time to avoid the lengthy refitting process by using the argument `load.ensemble = TRUE`.

```R
params_TRT = c(SLparams, save.ensemble = TRUE, ensemble.dir.path = "./h2o-ensemble-model-TRT")
```

The following example fits the propensity score using above SuperLearner to model the exposure mechanism and using `speedglm` logistic regressions for censoring and monitoring:
```R
params_CENS = list(fit.package = "speedglm", fit.algorithm = "glm")
params_MONITOR = list(fit.package = "speedglm", fit.algorithm = "glm")

OData <- fitPropensity(OData,
            gform_CENS = gform_CENS, stratify_CENS = stratify_CENS, params_CENS = params_CENS,
            gform_TRT = gform_TRT, params_TRT = params_TRT,
            gform_MONITOR = gform_MONITOR, params_MONITOR = params_MONITOR)
```

The following example loads the previously saved fits of the SuperLearner for the exposure. The only models fit during this call to `fitPropensity` are for the monitoring and censoring.
```R
params_TRT = c(SLparams, load.ensemble = TRUE, ensemble.dir.path = "./h2o-ensemble-model-TRT")

OData <- fitPropensity(OData,
            gform_CENS = gform_CENS, stratify_CENS = stratify_CENS, params_CENS = params_CENS,
            gform_TRT = gform_TRT, params_TRT = params_TRT,
            gform_MONITOR = gform_MONITOR, params_MONITOR = params_MONITOR)
```

The SuperLearner for TMLE and GCOMP is specified in an identical fashion. One needs to specify the relevant parameters and the ensemble models as part of the `models` argument. However, its currently not possible to save the individual SuperLearner fits of the outcome (Q) model.
 -->


### Some details on estimators

Currently implemented **estimators** include:

 - *Kaplan-Meier* Estimator. No adjustment for time-varying confounding or informative right-censoring.
 - *Inverse Probability Weighted (IPW) Kaplan-Meier (`survNPMSM`)*. Also known as the Adjusted Kaplan Meier (AKME). Also known as the saturated (non-parametric) IPW-MSM estimator of the survival hazard. This estimator inverse weights each observation based on the exposure/censoring model fits (propensity scores).
 - *Bounded Inverse Probability Weighted (B-IPW) Estimator of Survival('directIPW')*. Estimates the survival directly (without hazard), also based on the exposure/censoring model fit (propensity scores).
 - *Inverse Probability Weighted Marginal Structural Model (`survMSM`)* for the hazard function, mapped into survival. Currently only logistic regression is allowed where covariates are time-points and regime/rule indicators. This estimator is also based on the exposure/censoring model fit (propensity scores), but allows additional smoothing over multiple time-points and includes optional weight stabilization.
 - *Longitudinal G-formula (`GCOMP`)*. Also known as the iterative G-Computation formula or Q-learning. Directly estimates the outcome model while adjusting for time-varying confounding. Estimation can be stratified by rule/regime followed or pooled across all rules/regimes.
 - *Longitudinal Targeted Minimum-Loss-based Estimator (`TMLE`)*. Also known as L-TMLE. Doubly robust and semi-parametrically efficient estimator that de-biases each outcome regression fit with a targeting step, using IPW.
 - *Iterative TMLE (`iterTMLE`)* for longitudinal data. Fits sequential G-Computation and then iteratively performs targeting for all pooled Q's until convergence. 
 - *Infinite-dimensional TMLE (`iTMLE`)* for longitudinal data. Fits sequential G-Computation and performs additional *infinite-dimensional* targeting to achieve sequential double robustness. 

### Citation

...
<!-- To cite `stremr` in publications, please use:
> Sofrygin O, van der Laan MJ, Neugebauer R (2015). *stremr: Simulating Longitudinal Data with Causal Inference Applications.* R package version 0.1.
 -->

### Funding

...
<!-- The development of this package was partially funded through internal operational funds provided by the Kaiser Permanente Center for Effectiveness & Safety Research (CESR). This work was also partially supported through a Patient-Centered Outcomes Research Institute (PCORI) Award (ME-1403-12506) and an NIH grant (R01 AI074345-07).
 -->

### Copyright
The contents of this repository are distributed under the MIT license.
```
The MIT License (MIT)

Copyright (c) 2015-2017 Oleg Sofrygin 

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```
