% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/GRNTransPanel.R
\name{GRNTransPanel}
\alias{GRNTransPanel}
\alias{GRNTransPanelUI}
\alias{GRNTransPanelServer}
\title{Generate the GRN trans integration panel of the shiny app}
\usage{
GRNTransPanelUI(id, reference.table.name, comparison.table.name)

GRNTransPanelServer(
  id,
  expression.matrix,
  anno,
  anno.comparison,
  expression.matrix.comparison,
  tablenames,
  seed = 13
)
}
\arguments{
\item{id}{the input slot that will be used to access the value}

\item{expression.matrix}{the expression matrix; rows correspond to genes and
columns correspond to samples; usually preprocessed by
\code{\link{preprocessExpressionMatrix}}; a list  (of the same length as
modality) can be provided if #' \code{length(modality) > 1}}

\item{anno}{annotation data frame containing a match between the row names
of the expression.matrix (usually ENSEMBL IDs) and the gene names that
should be rendered within the app and in output files; this object is
created by \code{\link{generateShinyApp}} using the org.db specified}

\item{anno.comparison}{annotation data frame containing a match between the row names
of the comparison expression matrix and the names that
should be rendered within the app and in output files.
The structure matches the anno table created in
\code{\link{generateShinyApp}} using the org.db specified}

\item{expression.matrix.comparison}{Additional expression matrix to integrate.
Column names must match column names from expression.matrix.}

\item{tablenames, reference.table.name, comparison.table.name}{Names for reference and comparison expression tables.}

\item{seed}{Random seed to create reproducible GRNs}
}
\value{
The UI and Server components of the shiny module, that can be used
within the UI and Server definitions of a shiny app.
}
\description{
These are the UI and server components of the GRN trans integration
panel of the shiny app. It is generated by including at least 1 row in the
trans.integration parameter of \code{\link{generateShinyApp}}.
}
