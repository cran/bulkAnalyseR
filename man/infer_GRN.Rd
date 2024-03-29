% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/GRNfuns.R
\name{infer_GRN}
\alias{infer_GRN}
\title{Perform GRN inference}
\usage{
infer_GRN(
  expression.matrix,
  metadata,
  anno,
  seed = 13,
  targets,
  condition,
  samples,
  inference_method
)
}
\arguments{
\item{expression.matrix}{the expression matrix; rows correspond to genes and
columns correspond to samples; usually preprocessed by
\code{\link{preprocessExpressionMatrix}}; a list  (of the same length as
modality) can be provided if #' \code{length(modality) > 1}}

\item{metadata}{a data frame containing metadata for the samples contained
in the expression.matrix; must contain at minimum two columns:
the first column must contain the column names of the expression.matrix,
while the last column is assumed to contain the experimental conditions
that will be tested for differential expression; a list  (of the same
length as modality) can be provided if #' \code{length(modality) > 1}}

\item{anno}{annotation data frame containing a match between the row names
of the expression.matrix (usually ENSEMBL IDs) and the gene names that
should be rendered within the app and in output files; this object is
created by \code{\link{generateShinyApp}} using the org.db specified}

\item{seed}{the random seed to be set when running GRN inference, to ensure
reproducibility of outputs}

\item{targets}{the target genes of interest around which the GRN is built;
must be row names of the expression matrix}

\item{condition}{name of the metadata column to select samples from}

\item{samples}{names of the sample groups to select; must appear in
\code{metadata[[condition]]}}

\item{inference_method}{method used for GRN inference; only supported method
is currently GENIE3.}
}
\value{
The adjacency matrix of the inferred network
}
\description{
This function performs Gene Regulatory Network inference on
a subset of the expression matrix, for a set of potential targets
}
\examples{
expression.matrix.preproc <- as.matrix(read.csv(
  system.file("extdata", "expression_matrix_preprocessed.csv", package = "bulkAnalyseR"), 
  row.names = 1
))[1:500, ]

metadata <- data.frame(
  srr = colnames(expression.matrix.preproc), 
  timepoint = rep(c("0h", "12h", "36h"), each = 2)
)

anno <- AnnotationDbi::select(
  getExportedValue('org.Mm.eg.db', 'org.Mm.eg.db'),
  keys = rownames(expression.matrix.preproc),
  keytype = 'ENSEMBL',
  columns = 'SYMBOL'
) \%>\%
  dplyr::distinct(ENSEMBL, .keep_all = TRUE) \%>\%
  dplyr::mutate(NAME = ifelse(is.na(SYMBOL), ENSEMBL, SYMBOL))

res <- infer_GRN(
  expression.matrix = expression.matrix.preproc,
  metadata = metadata,
  anno = anno,
  seed = 13,
  targets = c("Hecw2", "Akr1cl"),
  condition = "timepoint",
  samples = "0h",
  inference_method = "GENIE3"
)
}
