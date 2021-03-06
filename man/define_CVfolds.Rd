% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/DataStorageClass.R
\name{define_CVfolds}
\alias{define_CVfolds}
\title{Define fold ID column for cross-validation}
\usage{
define_CVfolds(data, nfolds = 5, fold_column = "fold_ID", seed = NULL)
}
\arguments{
\item{data}{Object of class \code{DataStorageClass} (returned by calling \code{importData} function).}

\item{nfolds}{The number of folds to use in V fold cross-validation.}

\item{fold_column}{The name for the column that will contain the fold IDs.}

\item{seed}{Fix the seed for random generator.}
}
\description{
Define fold ID column for cross-validation
}
