% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/GRNfuns.R
\name{plot_GRN}
\alias{plot_GRN}
\title{Plot a GRN}
\usage{
plot_GRN(
  weightMat,
  anno,
  plotConnections,
  plot_position_grid,
  n_networks,
  recurring_regulators
)
}
\arguments{
\item{weightMat}{the (weighted) adjacency matrix - regulators in rows,
targets in columns}

\item{anno}{annotation data frame containing a match between the row names
of the expression.matrix (usually ENSEMBL IDs) and the gene names that
should be rendered within the app and in output files; this object is
created by \code{\link{generateShinyApp}} using the org.db specified}

\item{plotConnections}{the number of connections to subset to}

\item{plot_position_grid, n_networks}{the position of the plot in
the grid (1-4) and the number of networks shown (1-4); these are
solely used for hiding unwanted plots in the shiny app}

\item{recurring_regulators}{targets to be highlighted; usually the
result of \code{\link{find_regulators_with_recurring_edges}}}
}
\value{
A network plot. See visNetwork package for more details.
}
\description{
This function creates a network plot of a GRN.
}
\examples{
weightMat1 <- matrix(
  c(0.1, 0.4, 0.8, 0.3), nrow = 2, ncol = 2,
  dimnames = list("regulators" = c("r1", "r2"), "targets" = c("t1", "t2"))
)
weightMat2 <- matrix(
  c(0.1, 0.2, 0.8, 0.3), nrow = 2, ncol = 2,
  dimnames = list("regulators" = c("r1", "r2"), "targets" = c("t1", "t2"))
)
anno <- tibble::tibble(ENSEMBL = c("r1", "r2", "t1", "t2"), NAME = ENSEMBL)
recurring_regulators <- find_regulators_with_recurring_edges(list(weightMat1, weightMat2), 2)
plot_GRN(weightMat1, anno, 2, 1, 1, recurring_regulators)
plot_GRN(weightMat2, anno, 2, 1, 1, recurring_regulators)
}
