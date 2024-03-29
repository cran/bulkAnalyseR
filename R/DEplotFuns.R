#' Create a volcano plot visualising differential expression (DE) results
#' @description This function creates a volcano plot to visualise the results
#' of a DE analysis.
#' @param genes.de.results the table of DE genes, usually generated by
#' \code{\link{DEanalysis_edger}}
#' @param pval.threshold,lfc.threshold the p-value and/or log2(fold-change)
#' thresholds to determine whether a gene is DE
#' @param alpha the transparency of points; ignored for DE genes if 
#' add.expression.colour.gradient is TRUE; default is 0.1
#' @param xlims a single value to create (symmetric) x-axis limits; by default
#' inferred from the data
#' @param log10pval.cap whether to cap the log10(p-value at -10); any p-values
#' lower that 10^(-10) are set to the cap for plotting
#' @param add.colours whether to colour genes based on their log2(fold-change)
#' and -log10(p-value); default is TRUE
#' @param add.expression.colour.gradient whether to add a colour gradient
#' for DE genes to present their log2(expression); default is TRUE
#' @param add.guide.lines whether to add vertical and horizontal guide lines
#' to the plot to highlight the thresholds; default is TRUE
#' @param add.labels.auto whether to automatically label genes with the 
#' highest |log2(fold-change)| and expression; default is TRUE
#' @param add.labels.custom whether to add labels to user-specified genes;
#' the parameter genes.to.label must also be specified; default is FALSE
#' @param ... parameters passed on to \code{\link{volcano_enhance}}
#' @return The volcano plot as a ggplot object.
#' @export
#' @examples
#' expression.matrix.preproc <- as.matrix(read.csv(
#'   system.file("extdata", "expression_matrix_preprocessed.csv", package = "bulkAnalyseR"), 
#'   row.names = 1
#' ))[1:500, 1:4]
#' 
#' anno <- AnnotationDbi::select(
#'   getExportedValue('org.Mm.eg.db', 'org.Mm.eg.db'),
#'   keys = rownames(expression.matrix.preproc),
#'   keytype = 'ENSEMBL',
#'   columns = 'SYMBOL'
#' ) %>%
#'   dplyr::distinct(ENSEMBL, .keep_all = TRUE) %>%
#'   dplyr::mutate(NAME = ifelse(is.na(SYMBOL), ENSEMBL, SYMBOL))
#'   
#' edger <- DEanalysis_edger(
#'   expression.matrix = expression.matrix.preproc,
#'   condition = rep(c("0h", "12h"), each = 2),
#'   var1 = "0h",
#'   var2 = "12h",
#'   anno = anno
#' )
#' vp <- volcano_plot(edger)
#' print(vp)
volcano_plot <- function(
  genes.de.results,
  pval.threshold = 0.05, 
  lfc.threshold = 1,
  alpha = 0.1,
  xlims = NULL,
  log10pval.cap = TRUE,
  add.colours = TRUE,
  add.expression.colour.gradient = TRUE,
  add.guide.lines = TRUE,
  add.labels.auto = TRUE,
  add.labels.custom = FALSE,
  ...
){
  df = genes.de.results %>%
    dplyr::mutate(gene = .data$gene_name, log10pval = log10(.data$pvalAdj)) %>%
    dplyr::filter(!is.na(.data$log10pval))
  
  if(all(df$log10pval >= -10)) log10pval.cap <- FALSE
  if(log10pval.cap) df$log10pval[df$log10pval < -10] <- -10
  
  log2FC <- NULL; log10pval <- NULL
  vp <- ggplot(data = df, mapping = aes(x = log2FC, y = -log10pval)) +
    theme_minimal() +
    xlab("log2(FC)") +
    ylab("-log10(pval)") 
  
  if(is.null(xlims)){
    max.abs.lfc = max(abs(df[df$log10pval > -Inf,]$log2FC))
    vp <- vp + xlim(-max.abs.lfc, max.abs.lfc)
  }else{
    vp <- vp + xlim(-abs(xlims), abs(xlims))
  }
  
  if(log10pval.cap){
    vp <- vp + scale_y_continuous(labels=c("0.0", "2.5", "5.0", "7.5", ">10"))
  }
  
  if(any(add.colours, 
         add.expression.colour.gradient,
         add.guide.lines,
         add.labels.auto,
         add.labels.custom)){
    vp <- volcano_enhance(
      vp = vp,
      df = df,
      pval.threshold = pval.threshold,
      lfc.threshold = lfc.threshold,
      alpha = alpha,
      add.colours = add.colours,
      add.expression.colour.gradient = add.expression.colour.gradient,
      add.guide.lines = add.guide.lines,
      add.labels.auto = add.labels.auto,
      add.labels.custom = add.labels.custom,
      ...
    )
  }
  
  return(vp)
  
}

#' @description \code{\link{volcano_enhance}} is called indirectly by 
#' \code{\link{volcano_plot}} to add extra features.
#' @param vp volcano plot as a ggplot object (usually passed by \code{\link{volcano_plot}})
#' @param df data frame of DE results for all genes (usually passed by 
#' \code{\link{volcano_plot}})
#' @param point.colours a vector of 4 colours to colour genes with both pval
#' and lfc under thresholds, just pval under threshold, just lfc under threshold,
#' both pval and lfc over threshold (DE genes) respectively; only used if
#' add.colours is TRUE
#' @param raster whether to rasterize non-DE genes with ggraster to reduce
#' memory usage; particularly useful when saving plots to files
#' @param colour.gradient.scale a vector of two colours to create a colour
#' gradient for colouring the DE genes based on expression; a named list with
#' components left and right can be supplied to use two different colour scales;
#' only used if add.expression.colour.gradient is TRUE
#' @param colour.gradient.breaks,colour.gradient.limits parameters to customise
#' the legend of the colour gradient scale; especially useful if creating
#' multiple plots or a plot with two scales;
#' only used if add.expression.colour.gradient is TRUE
#' @param guide.line.colours a vector with two colours to be used to colour
#' the guide lines; the first colour is used for the p-value and log2(fold-change)
#' thresholds and the second for double those values
#' @param annotation annotation data frame containing a match between the gene
#' field of df (usually ENSEMBL IDs) and the gene names that should be shown
#' in the plot labels; not necessary if df already contains gene names
#' @param n.labels.auto a integer vector of length 3 denoting the number of
#' genes that should be automatically labelled; the first entry corresponds to
#' DE genes with the lowest p-value, the second to those with highest absolute
#' log2(fold-change) and the third to those with highest expression; a single
#' integer can also be specified, to be used for all 3 entries; default is 5
#' @param genes.to.label a vector of gene names to be labelled in the
#' plot; if names are present those are shown as the labels (but the values are
#' the ones matched - this is to allow custom gene names to be presented)
#' @param seed the random seed to be used for reproducibility; only used for
#' ggrepel::geom_label_repel if labels are present
#' @param label.force passed to the force argument of ggrepel::geom_label_repel;
#' higher values make labels overlap less (at the cost of them being further
#' away from the points they are labelling)
#' @return The enhanced volcano plot as a ggplot object.
#' @export
#' @rdname volcano_plot
volcano_enhance <- function(
  vp,
  df,
  pval.threshold,
  lfc.threshold,
  alpha,
  add.colours,
  point.colours = c("#bfbfbf", "orange", "red", "blue"),
  raster = FALSE,
  add.expression.colour.gradient,
  colour.gradient.scale = list(left  = c("#99e6ff", "#000066"),
                               right = c("#99e6ff", "#000066")),
  colour.gradient.breaks = waiver(),
  colour.gradient.limits = NULL,
  add.guide.lines,
  guide.line.colours = c("green", "blue"),
  add.labels.auto,
  add.labels.custom,
  annotation = NULL,
  n.labels.auto = c(5, 5, 5),
  genes.to.label = NULL,
  seed = 0,
  label.force = 1
){
  
  logp.threshold = log10(pval.threshold)
  
  if(add.colours){
    colours = vector(length=nrow(df))
    colours[] = point.colours[1]
    colours[abs(df$log2FC) > lfc.threshold] = point.colours[2]
    colours[df$log10pval < logp.threshold] = point.colours[3]
    colours[abs(df$log2FC) > lfc.threshold & df$log10pval < logp.threshold] = point.colours[4]
    df$colours <- colours
    
    if(raster){
      vp <- vp + ggrastr::rasterise(geom_point(alpha = alpha, colour = colours))
    }else{
      vp <- vp + geom_point(alpha = alpha, colour = colours, fill = colours)
    }
  }
  
  if(add.expression.colour.gradient){
    df.colour.gradient <- df %>%
      dplyr::filter(abs(.data$log2FC) > lfc.threshold & .data$log10pval < logp.threshold) %>%
      dplyr::arrange(.data$log2exp)
    if(identical(colour.gradient.scale$left, colour.gradient.scale$right)){
      vp <- vp +
        geom_point(data = df.colour.gradient,
                   mapping = aes(x = .data$log2FC, y = -.data$log10pval, colour = .data$log2exp)) +
        scale_color_gradient(low = colour.gradient.scale$left[1], 
                             high = colour.gradient.scale$left[2],
                             breaks = colour.gradient.breaks,
                             limits = colour.gradient.limits) +
        labs(colour = "log2(exp)")
    }else{
      vp <- vp +
        geom_point(data = dplyr::filter(df.colour.gradient, .data$log2FC < 0),
                   mapping = aes(x = .data$log2FC, y = -.data$log10pval, colour = .data$log2exp)) +
        scale_color_gradient(low = colour.gradient.scale$left[1], 
                             high = colour.gradient.scale$left[2],
                             breaks = colour.gradient.breaks,
                             limits = colour.gradient.limits) +
        labs(colour = "log2(exp)") +
        ggnewscale::new_scale_colour() +
        geom_point(data = dplyr::filter(df.colour.gradient, .data$log2FC > 0),
                   mapping = aes(x = .data$log2FC, y = -.data$log10pval, colour = .data$log2exp)) +
        scale_colour_gradient(low = colour.gradient.scale$right[1], 
                              high = colour.gradient.scale$right[2],
                              breaks = colour.gradient.breaks,
                              limits = colour.gradient.limits) +
        labs(colour = "log2(exp)")
    }
  }
  
  if(add.guide.lines){
    vp <- vp +
      geom_vline(xintercept =      lfc.threshold,  colour = guide.line.colours[1]) +
      geom_vline(xintercept =     -lfc.threshold,  colour = guide.line.colours[1]) +
      geom_vline(xintercept =  2 * lfc.threshold,  colour = guide.line.colours[2]) +
      geom_vline(xintercept = -2 * lfc.threshold,  colour = guide.line.colours[2]) +
      geom_hline(yintercept =     -logp.threshold, colour = guide.line.colours[1]) +
      geom_hline(yintercept = -2 * logp.threshold, colour = guide.line.colours[2])
  }
  
  if(add.labels.auto | add.labels.custom){
    if(!is.null(annotation)){
      df <- df %>% 
        dplyr::mutate(
          symbol = annotation$SYMBOL[match(.data$gene, annotation$ENSEMBL)],
          name = ifelse(is.na(.data$symbol), .data$gene, .data$symbol)
        ) %>%
        dplyr::select(-.data$symbol)
    }else{
      df <- df %>% dplyr::mutate(name = .data$gene)
    }
    
    df.label <- tibble::tibble()
    if(add.labels.custom){
      genes.to.rename <- genes.to.label[names(genes.to.label) != ""]
      genes.to.label <- df$name[(match(genes.to.label, c(df$name, df$gene)) - 1) %% nrow(df) + 1]
      genes.to.label <- unique(genes.to.label[!is.na(genes.to.label)])
      genes.to.rename <- genes.to.rename[genes.to.rename %in% genes.to.label]
      df.label <- dplyr::filter(df, .data$name %in% genes.to.label)
      df.label$name[match(genes.to.rename, df.label$name)] <- names(genes.to.rename)
      if(nrow(df.label) == 0){
        message(paste0("add.labels.custom was TRUE but no genes specified; ",
                       "did you forget to supply genes.to.label or annotation?"))
      }
    }
    
    if(add.labels.auto){
      if(length(n.labels.auto) == 1) n.labels.auto <- rep(n.labels.auto, 3)
      df.significant <- dplyr::filter(df, !(.data$name %in% genes.to.label))
      
      df.significant <- df.significant[order(abs(df.significant$log2FC), decreasing=TRUE), ]
      df.highest.lfc <- utils::head(df.significant, n.labels.auto[1])
      df.rest <- utils::tail(df.significant, nrow(df.significant) - n.labels.auto[1]) %>%
        dplyr::filter(abs(.data$log2FC) > lfc.threshold, .data$log10pval < logp.threshold)
      
      df.rest <- df.rest[order(abs(df.rest$log10pval), decreasing=TRUE), ]
      df.lowest.p.vals <- utils::head(df.rest, n.labels.auto[2])
      df.rest <- utils::tail(df.rest, nrow(df.rest) - n.labels.auto[2])
      
      df.rest <- df.rest[order(df.rest$log2exp, decreasing=TRUE), ]
      df.highest.abn <- utils::head(df.rest, n.labels.auto[3])
      
      df.label <- rbind(df.lowest.p.vals, df.highest.lfc, df.highest.abn, df.label) %>%
        dplyr::distinct(.data$name, .keep_all = TRUE)
    }
    
    set.seed(seed = seed)
    vp <- vp +
      ggrepel::geom_label_repel(
        data = df.label, 
        mapping = aes(x = .data$log2FC, y = -.data$log10pval, label = .data$name),
        max.overlaps = Inf,
        force = label.force,
        point.size = NA
      )
  }
  
  return(vp)
  
}

#' Create an MA plot visualising differential expression (DE) results
#' @description This function creates an MA plot to visualise the results
#' of a DE analysis.
#' @inheritParams volcano_plot
#' @param ylims a single value to create (symmetric) y-axis limits; by default
#' inferred from the data
#' @param ... parameters passed on to \code{\link{ma_enhance}}
#' @return The MA plot as a ggplot object.
#' @export
#' @examples
#' expression.matrix.preproc <- as.matrix(read.csv(
#'   system.file("extdata", "expression_matrix_preprocessed.csv", package = "bulkAnalyseR"), 
#'   row.names = 1
#' ))[1:500, 1:4]
#' 
#' anno <- AnnotationDbi::select(
#'   getExportedValue('org.Mm.eg.db', 'org.Mm.eg.db'),
#'   keys = rownames(expression.matrix.preproc),
#'   keytype = 'ENSEMBL',
#'   columns = 'SYMBOL'
#' ) %>%
#'   dplyr::distinct(ENSEMBL, .keep_all = TRUE) %>%
#'   dplyr::mutate(NAME = ifelse(is.na(SYMBOL), ENSEMBL, SYMBOL))
#'   
#' edger <- DEanalysis_edger(
#'   expression.matrix = expression.matrix.preproc,
#'   condition = rep(c("0h", "12h"), each = 2),
#'   var1 = "0h",
#'   var2 = "12h",
#'   anno = anno
#' )
#' mp <- ma_plot(edger)
#' print(mp)
ma_plot <- function(
  genes.de.results,
  pval.threshold = 0.05, 
  lfc.threshold = 1,
  alpha = 0.1,
  ylims = NULL,
  add.colours = TRUE,
  add.expression.colour.gradient = TRUE,
  add.guide.lines = TRUE,
  add.labels.auto = TRUE,
  add.labels.custom = FALSE,
  ...
){
  df = genes.de.results %>%
    dplyr::mutate(gene = .data$gene_name, log10pval = log10(.data$pvalAdj)) %>%
    dplyr::filter(!is.na(.data$log10pval))
  
  log2exp <- NULL; log2FC <- NULL
  p <- ggplot(data = df, mapping = aes(x = log2exp, y = log2FC)) +
    ggplot2::theme_minimal() +
    xlab("Average log2(exp)") +
    ylab("log2(FC)")
  
  if(is.null(ylims)){
    max.abs.lfc = max(abs(df$log2FC))
    p <- p + ylim(-max.abs.lfc, max.abs.lfc)
  }else{
    p <- p + ylim(-abs(ylims), abs(ylims))
  }
  
  if(any(add.colours, 
         add.expression.colour.gradient,
         add.guide.lines,
         add.labels.auto,
         add.labels.custom)){
    p <- ma_enhance(
      p = p,
      df = df,
      pval.threshold = pval.threshold,
      lfc.threshold = lfc.threshold,
      alpha = alpha,
      add.colours = add.colours,
      add.expression.colour.gradient = add.expression.colour.gradient,
      add.guide.lines = add.guide.lines,
      add.labels.auto = add.labels.auto,
      add.labels.custom = add.labels.custom,
      ...
    )
  }
  
  return(p)
  
}

#' Add features to an MA plot visualising differential expression (DE) results
#' @description \code{\link{ma_enhance}} is called indirectly by 
#' \code{\link{ma_plot}} to add extra features.
#' @param p MA plot as a ggplot object (usually passed by \code{\link{ma_plot}})
#' @param df data frame of DE results for all genes (usually passed by 
#' \code{\link{ma_plot}})
#' @return The enhanced MA plot as a ggplot object.
#' @export
#' @rdname ma_plot
ma_enhance <- function(
  p,
  df,
  pval.threshold,
  lfc.threshold,
  alpha,
  add.colours,
  point.colours = c("#bfbfbf", "orange", "red", "blue"),
  raster = FALSE,
  add.expression.colour.gradient,
  colour.gradient.scale = list(left  = c("#99e6ff", "#000066"),
                               right = c("#99e6ff", "#000066")),
  colour.gradient.breaks = waiver(),
  colour.gradient.limits = NULL,
  add.guide.lines,
  guide.line.colours = c("green", "blue"),
  add.labels.auto,
  add.labels.custom,
  annotation = NULL,
  n.labels.auto = c(5, 5, 5),
  genes.to.label = NULL,
  seed = 0,
  label.force = 1
){
  
  logp.threshold = log10(pval.threshold)
  
  if(add.colours){
    colours = vector(length=nrow(df))
    colours[] = point.colours[1]
    colours[abs(df$log2FC) > lfc.threshold] = point.colours[2]
    colours[df$log10pval < logp.threshold] = point.colours[3]
    colours[abs(df$log2FC) > lfc.threshold & df$log10pval < logp.threshold] = point.colours[4]
    df$colours <- colours
    
    if(raster){
      p <- p + ggrastr::rasterise(geom_point(alpha = alpha, colour = colours))
    }else{
      p <- p + geom_point(alpha = alpha, colour = colours, fill = colours)
    }
  }
  
  if(add.expression.colour.gradient){
    df.colour.gradient <- df %>%
      dplyr::filter(abs(.data$log2FC) > lfc.threshold & .data$log10pval < logp.threshold) %>%
      dplyr::arrange(.data$log2exp)
    if(identical(colour.gradient.scale$left, colour.gradient.scale$right)){
      p <- p +
        geom_point(data = df.colour.gradient,
                   mapping = aes(x = .data$log2exp, y = .data$log2FC, colour = .data$log2exp)) +
        scale_color_gradient(low = colour.gradient.scale$left[1], 
                             high = colour.gradient.scale$left[2],
                             breaks = colour.gradient.breaks,
                             limits = colour.gradient.limits) +
        labs(colour = "log2(exp)")
    }else{
      p <- p +
        geom_point(data = dplyr::filter(df.colour.gradient, .data$log2FC < 0),
                   mapping = aes(x = .data$log2exp, y = .data$log2FC, colour = .data$log2exp)) +
        scale_color_gradient(low = colour.gradient.scale$left[1], 
                             high = colour.gradient.scale$left[2],
                             breaks = colour.gradient.breaks,
                             limits = colour.gradient.limits) +
        labs(colour = "log2(exp)") +
        ggnewscale::new_scale_colour() +
        geom_point(data = dplyr::filter(df.colour.gradient, .data$log2FC > 0),
                   mapping = aes(x = .data$log2exp, y = .data$log2FC, colour = .data$log2exp)) +
        scale_colour_gradient(low = colour.gradient.scale$right[1], 
                              high = colour.gradient.scale$right[2],
                              breaks = colour.gradient.breaks,
                              limits = colour.gradient.limits) +
        labs(colour = "log2(exp)")
    }
  }
  
  if(add.guide.lines){
    p <- p +
      geom_hline(yintercept =      lfc.threshold,  colour = guide.line.colours[1]) +
      geom_hline(yintercept =     -lfc.threshold,  colour = guide.line.colours[1]) +
      geom_hline(yintercept =  2 * lfc.threshold,  colour = guide.line.colours[2]) +
      geom_hline(yintercept = -2 * lfc.threshold,  colour = guide.line.colours[2])
  }
  
  if(add.labels.auto | add.labels.custom){
    if(!is.null(annotation)){
      df <- df %>% 
        dplyr::mutate(
          symbol = annotation$SYMBOL[match(.data$gene, annotation$ENSEMBL)],
          name = ifelse(is.na(.data$symbol), .data$gene, .data$symbol)
        ) %>%
        dplyr::select(-.data$symbol)
    }else{
      df <- df %>% dplyr::mutate(name = .data$gene)
    }
    
    df.label <- tibble::tibble()
    if(add.labels.custom){
      genes.to.rename <- genes.to.label[names(genes.to.label) != ""]
      genes.to.label <- df$name[(match(genes.to.label, c(df$name, df$gene)) - 1) %% nrow(df) + 1]
      genes.to.label <- unique(genes.to.label[!is.na(genes.to.label)])
      genes.to.rename <- genes.to.rename[genes.to.rename %in% genes.to.label]
      df.label <- dplyr::filter(df, .data$name %in% genes.to.label)
      df.label$name[match(genes.to.rename, df.label$name)] <- names(genes.to.rename)
      if(nrow(df.label) == 0){
        message(paste0("add.labels.custom was TRUE but no genes specified; ",
                       "did you forget to supply genes.to.label or annotation?"))
      }
    }
    
    if(add.labels.auto){
      if(length(n.labels.auto) == 1) n.labels.auto <- rep(n.labels.auto, 3)
      df.significant <- dplyr::filter(df, !(.data$name %in% genes.to.label))
      df.significant <- df.significant[order(abs(df.significant$log2FC), decreasing=TRUE), ]
      df.highest.lfc <- utils::head(df.significant, n.labels.auto[1])
      df.rest <- utils::tail(df.significant, nrow(df.significant) - n.labels.auto[1]) %>%
        dplyr::filter(abs(.data$log2FC) > lfc.threshold, .data$log10pval < logp.threshold)
      
      df.rest <- df.rest[order(abs(df.rest$log10pval), decreasing=TRUE), ]
      df.lowest.p.vals <- utils::head(df.rest, n.labels.auto[2])
      df.rest <- utils::tail(df.rest, nrow(df.rest) - n.labels.auto[2])
      
      df.rest <- df.rest[order(df.rest$log2exp, decreasing=TRUE), ]
      df.highest.abn <- utils::head(df.rest, n.labels.auto[3])
      
      df.label <- rbind(df.lowest.p.vals, df.highest.lfc, df.highest.abn, df.label) %>%
        dplyr::distinct(.data$name, .keep_all = TRUE)
    }
    
    set.seed(seed = seed)
    p <- p +
      ggrepel::geom_label_repel(
        data = df.label, 
        mapping = aes(x = .data$log2exp, y = .data$log2FC, label = .data$name),
        max.overlaps = Inf,
        force = label.force,
        point.size = NA
      )
  }
  return(p)
}