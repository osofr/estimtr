## Update to fix error with data.table package:

* This update fixes the current error with data.table package.

## Test environments:
* local OS X install, R 3.3.1
* Ubuntu 12.04 R 3.3.1
* win-builder (devel and release)

## R CMD check results
There were no ERRORs or WARNINGs. 

There was 1 NOTE:

* Possibly mis-spelled words in DESCRIPTION:
  GCOMP (12:31)
  IPW (12:17, 12:26)
  MSM (12:22)
  TMLE (12:51)

These are not mis-spelled. I manually checked all of these words. 
They define specific estimators / terms that are known to the intended user.


## Update to catch pandoc error:

* As requested, also putting 'h2oEnsemble' inside single quotes.

* This update performs checks for pandoc availability. Addresses the test error on Solaris: https://cran.r-project.org/web/checks/check_results_stremr.html

## Test environments:
* local OS X install, R 3.2.4
* Ubuntu 12.04 R 3.3.1
* win-builder (devel and release)

## R CMD check results
There were no ERRORs or WARNINGs. 

There were 2 NOTEs:

* Possibly mis-spelled words in DESCRIPTION:
  GCOMP (12:31)
  IPW (12:17, 12:26)
  MSM (12:22)
  SuperLearner (15:5)
  TMLE (12:51)
  oEnsemble (15:21)

These are not mis-spelled. I manually checked all of these words. 
They define specific estimators / terms that are known to the intended user.

* Package suggested but not available for checking: 'h2oEnsemble'

This package provides important additional functionality to stremr. Source code for h2oEnsemble is available from valid repo listed in "Additional_repositories". Appropriate error checks and messages have been implemented throughout the package whenever h2oEnsemble is not installed. Currently, the error message instructs the user on how to install it directly from github, i.e.,
"Package h2oEnsemble is needed for modeling with SuperLearner.
Please install it by typing this into R terminal:
  library(devtools)
  install_github(\"h2oai/h2o-3/h2o-r/ensemble/h2oEnsemble-package\")"
Finally, the maintainer of h2oEnsemble has promised to release it to CRAN very soon.

## Re-submission to CRAN:

## Test environments:
* local OS X install, R 3.2.4
* Ubuntu 12.04 R 3.3.1
* win-builder (devel and release)

## R CMD check results
There were no ERRORs or WARNINGs. 

There were 2 NOTEs:

* Possibly mis-spelled words in DESCRIPTION:
  GCOMP (12:31)
  IPW (12:17, 12:26)
  MSM (12:22)
  SuperLearner (15:5)
  TMLE (12:51)
  oEnsemble (15:21)

These are not mis-spelled. I manually checked all of these words. 
They define specific estimators / terms that are known to the intended user.

* Package suggested but not available for checking: 'h2oEnsemble'

This package provides important additional functionality to stremr. Source code for h2oEnsemble is available from valid repo listed in "Additional_repositories". Appropriate error checks and messages have been implemented throughout the package whenever h2oEnsemble is not installed. Currently, the error message instructs the user on how to install it directly from github, i.e.,
"Package h2oEnsemble is needed for modeling with SuperLearner.
Please install it by typing this into R terminal:
  library(devtools)
  install_github(\"h2oai/h2o-3/h2o-r/ensemble/h2oEnsemble-package\")"
Finally, the maintainer of h2oEnsemble has promised to release it to CRAN very soon.

Previous NOTEs:

* (FIXED) Additional repositories with no packages:
* (FIXED) Version contains leading zeroes (0.0.4.0000)
* (FIXED) Found the following (possibly) invalid URLs:
  URL: http://cran.r-project.org/package=stremr
  URL: http://cran.rstudio.com/web/packages/stremr/index.html


## Initial Submission to CRAN:

## Test environments:
* local OS X install, R 3.2.4
* Ubuntu 12.04 R 3.3.1
* win-builder (devel and release)

## R CMD check results
There were no ERRORs or WARNINGs. 

There were 2 NOTEs:

* Possibly mis-spelled words in DESCRIPTION:
All of these words define specific estimators / terms that will be known to the intended user.

* Additional repositories with no packages:
https://github.com/h2oai/h2o-3/tree/master/h2o-r/ensemble/h2oEnsemble-package

This is a direct repository link that contains the needed package. Also see below.

* Package suggested but not available for checking: ‘h2oEnsemble’

This package provides an important added functionality for stremr and is available for easy installation from github. A reference to its github repository has been added to the field "Additional_repositories:". Appropriate error checks and messages have been implemented throughout the package. 
Currently, the error message instructs the user on how to install it directly from github, i.e.,
"Package h2oEnsemble is needed for modeling with SuperLearner.
Please install it by typing this into R terminal:
  library(devtools)
  install_github(\"h2oai/h2o-3/h2o-r/ensemble/h2oEnsemble-package\")"
Finally, the maintainer of h2oEnsemble has promised to release the package to CRAN very soon.

