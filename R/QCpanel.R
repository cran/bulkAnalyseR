#' Generate the QC panel of the shiny app
#' @description These are the UI and server components of the QC panel of the 
#' shiny app. It is generated by including 'QC' in the panels.default argument
#' of \code{\link{generateShinyApp}}.
#' @inheritParams DEpanel
#' @return The UI and Server components of the shiny module, that can be used
#' within the UI and Server definitions of a shiny app.
#' @name QCpanel
NULL

#' @rdname QCpanel
#' @export
QCpanelUI <- function(id, metadata, show = TRUE){
  ns <- NS(id)
  
  if(show){
    tabPanel(
      'Quality checks',
      tags$h1("Jaccard Similarity Index Heatmap"),
      shinyWidgets::dropdownButton(
        shinyjqui::orderInput(ns('jaccard.annotations'), label = "Show annotations", items = colnames(metadata)),
        sliderInput(ns('jaccard.n.abundant'), label = '# of (most abundant) genes',
                    min = 50, value = 500, max = 5000, step = 50, ticks = FALSE),
        checkboxInput(ns("jaccard.show.values"), label = "Show JSI values", value = FALSE),
        textInput(ns('plotJSIFileName'), 'File name for JSI plot download', value ='JSIPlot.png'),
        downloadButton(ns('downloadJSIPlot'), 'Download JSI Plot'),
        
        status = "info",
        icon = icon("gear", verify_fa = FALSE), 
        tooltip = shinyWidgets::tooltipOptions(title = "Click to see inputs!")
      ),
      plotOutput(ns('jaccard')),
      
      tags$h1("Principal Component Analysis"),
      shinyWidgets::dropdownButton(
        radioButtons(ns('pca.annotation'), label = "Group by",
                     choices = colnames(metadata), selected = colnames(metadata)[ncol(metadata)]),
        sliderInput(ns('pca.n.abundant'), label = '# of (most abundant) genes',
                    min = 50, value = 500, max = 5000, step = 50, ticks = FALSE),
        checkboxInput(ns("pca.show.labels"), label = "Show sample labels", value = FALSE),
        checkboxInput(ns('pca.show.ellipses'),label = "Show ellipses around groups",value=TRUE),
        textInput(ns('plotPCAFileName'), 'File name for PCA plot download', value ='PCAPlot.png'),
        downloadButton(ns('downloadPCAPlot'), 'Download PCA Plot'),
        
        status = "info",
        icon = icon("gear", verify_fa = FALSE), 
        tooltip = shinyWidgets::tooltipOptions(title = "Click to see inputs!")
      ),
      plotOutput(ns('pca')),
      
      tags$h1("MA plots"),
      shinyWidgets::dropdownButton(
        selectInput(ns("maGeneName"), "Genes to highlight:", multiple = TRUE, choices = character(0)),
        checkboxInput(ns("ma.show.guidelines"), label = "Show guidelines", value = TRUE),
        selectInput(ns('ma.sample1'), 'Sample 1', choices = metadata[, 1], selected = metadata[1, 1]),
        selectInput(ns('ma.sample2'), 'Sample 2', choices = metadata[, 1], selected = metadata[2, 1]),
        shinyWidgets::switchInput(
          inputId = ns('autoLabel'),
          label = "Auto labels", 
          labelWidth = "80px",
          onLabel = 'On',
          offLabel = 'Off',
          value = FALSE,
          onStatus = FALSE
        ),
        selectInput(ns("geneName"), "Other genes to highlight:", multiple = TRUE, choices = character(0)),
        textInput(ns('plotMAFileName'), 'File name for MA plot download', value = 'MAPlot.png'),
        downloadButton(ns('downloadMAPlot'), 'Download MA Plot'),
        
        status = "info",
        icon = icon("gear", verify_fa = FALSE), 
        tooltip = shinyWidgets::tooltipOptions(title = "Click to see inputs!")
      ),
      plotOutput(ns('ma')),
      
      tags$h1("Scatter plots"),
      shinyWidgets::dropdownButton(
        selectInput(ns('scatter_sample1'), 'Sample 1', choices = metadata[, 1], selected = metadata[1, 1]),
        selectInput(ns('scatter_sample2'), 'Sample 2', choices = metadata[, 1], selected = metadata[2, 1]),
        selectInput(ns("scatterGeneName"), "Genes to highlight:", multiple = TRUE, choices = character(0)),
        textInput(ns('plotScatterFileName'), 'File name for scatter plot download', value = 'ScatterPlot.png'),
        downloadButton(ns('downloadScatterPlot'), 'Download Scatter Plot'),
        
        status = "info",
        icon = icon("gear", verify_fa = FALSE), 
        tooltip = shinyWidgets::tooltipOptions(title = "Click to see inputs!")
      ),
      plotOutput(ns('scatter')),
      
      tags$h1("Density plots"),
      shinyWidgets::dropdownButton(
        radioButtons(ns('density.annotation'), label = "Group by",
                     choices = colnames(metadata), selected = colnames(metadata)[1]),
        textInput(ns('plotDensityFileName'), 'File name for density plot download', value ='DensityPlot.png'),
        downloadButton(ns('downloadDensityPlot'), 'Download Density Plot'),
        
        status = "info",
        icon = icon("gear", verify_fa = FALSE), 
        tooltip = shinyWidgets::tooltipOptions(title = "Click to see inputs!")
      ),
      plotOutput(ns('density')),
      
      tags$h1("Violin plots"),
      shinyWidgets::dropdownButton(
        radioButtons(ns('violin.annotation'), label = "Colour by",
                     choices = colnames(metadata), selected = colnames(metadata)[ncol(metadata)]),
        checkboxInput(ns('violin.log.transformation'),label = 'Apply log transformation to expression',value = TRUE),
        textInput(ns('plotViolinFileName'), 'File name for violin plot download', value ='ViolinPlot.png'),
        downloadButton(ns('downloadViolinPlot'), 'Download Violin Plot'),
        
        status = "info",
        icon = icon("gear", verify_fa = FALSE), 
        tooltip = shinyWidgets::tooltipOptions(title = "Click to see inputs!")
      ),
      plotOutput(ns('violin')),
      
      tags$h1("Individual gene expression"),
      selectInput(ns("barGeneName"), "Genes to include:", multiple = TRUE, choices = character(0)),
      shinyWidgets::dropdownButton(
        checkboxInput(ns('bar.log.transformation'),label = 'Apply log transformation to expression',value = TRUE),
        textInput(ns('plotBarFileName'), 'File name for bar plot download', value ='BarPlot.png'),
        downloadButton(ns('downloadBarPlot'), 'Download Bar Plot'),
        
        status = "info",
        icon = icon("gear", verify_fa = FALSE), 
        tooltip = shinyWidgets::tooltipOptions(title = "Click to see inputs!")
      ),
      plotOutput(ns('barplot'))
      
    )
  }else{
    NULL
  }
}

#' @rdname QCpanel
#' @export
QCpanelServer <- function(id, expression.matrix, metadata, anno){
  # check whether inputs (other than id) are reactive or not
  stopifnot({
    is.reactive(expression.matrix)
    is.reactive(metadata)
    !is.reactive(anno)
  })
  
  moduleServer(id, function(input, output, session){
    
    #Set up server-side search for gene names
    updateSelectizeInput(session, "barGeneName", choices = anno$NAME, server = TRUE, selected = anno$NAME[1:2])
    updateSelectizeInput(session, "maGeneName", choices = anno$NAME, server = TRUE)
    updateSelectizeInput(session, "scatterGeneName", choices = anno$NAME, server = TRUE)
    
    observe({
      items <- colnames(metadata())
      include.exclude <- apply(metadata(), 2, function(x){
        l <- length(unique(x))
        (l > 1) & (l < length(x))
      })
      if (sum(include.exclude == TRUE) != 0){
      items <- colnames(metadata())[include.exclude]
      items <- items[c(length(items), seq_len(length(items) - 1))]
      } else {items = colnames(metadata())[2:ncol(metadata())]}
      shinyjqui::updateOrderInput(session, "jaccard.annotations", items = items)
    })
    
    #Set up server-side search for gene names
    updateSelectizeInput(session, "geneName", choices = anno$NAME, server = TRUE)
    
    jaccard.plot <- reactive({
      meta <- lapply(metadata(), function(x) if(!is.factor(x)){factor(x, levels = unique(x))}else{x}) %>% 
        as.data.frame() %>%
        dplyr::arrange(dplyr::across(input[['jaccard.annotations']]))
      myplot <- jaccard_heatmap(
        expression.matrix = expression.matrix()[, meta[, 1]],
        metadata = meta,
        top.annotation.ids = match(input[['jaccard.annotations']], colnames(meta)),
        n.abundant = input[['jaccard.n.abundant']], 
        show.values = input[["jaccard.show.values"]],
        show.row.column.names = (nrow(meta) <= 20)
      )
      myplot 
    })
    output[['jaccard']] <- renderPlot(jaccard.plot())
    
    pca.plot <- reactive({
      myplot <- plot_pca(
        expression.matrix = expression.matrix(),
        metadata = metadata(),
        annotation.id = match(input[['pca.annotation']], colnames(metadata())),
        n.abundant = input[['pca.n.abundant']],
        show.labels = input[['pca.show.labels']],
        show.ellipses = input[['pca.show.ellipses']]
      )
      myplot
    })
    output[['pca']] <- renderPlot(pca.plot())
    
    observe({
      updateSelectInput(session, 'ma.sample1', choices = metadata()[, 1], selected = metadata()[1, 1])
      updateSelectInput(session, 'ma.sample2', choices = metadata()[, 1], selected = metadata()[2, 1])
      updateSelectInput(session, 'scatter_sample1', choices = metadata()[, 1], selected = metadata()[1, 1])
      updateSelectInput(session, 'scatter_sample2', choices = metadata()[, 1], selected = metadata()[2, 1])

    })
    ma.plot <- reactive({
      highlightGenes <- input[["maGeneName"]]
      gene_id <- NULL; exp1 <- NULL; exp2 <- NULL; l1 <- NULL; l2 <- NULL
      df <- tibble::tibble(
        gene_id = rownames(expression.matrix()),
        gene_name = anno$NAME[match(gene_id, anno$ENSEMBL)],
        exp1 = expression.matrix()[, match(input[['ma.sample1']], colnames(expression.matrix()))],
        exp2 = expression.matrix()[, match(input[['ma.sample2']], colnames(expression.matrix()))],
        l1 = log2(exp1),
        l2 = log2(exp2),
        log2exp = (l1 + l2) / 2,
        log2FC = l1 - l2,
        pval = 1,
        pvalAdj = 1
      )  %>%
        dplyr::filter(exp1 != 0, exp2 != 0)
      highlightGenes <- input[["geneName"]]
      myplot <- ma_plot(
        genes.de.results = df,
        alpha = 0.05,
        add.colours = TRUE,
        point.colours = rep(scales::hue_pal()(1), 4),
        add.expression.colour.gradient = FALSE,
        add.guide.lines = input[['ma.show.guidelines']],
        guide.line.colours = rep("gray60", 2),
        add.labels.auto = input[["autoLabel"]],
        n.labels.auto = c(5, 5, 5),
        add.labels.custom = length(highlightGenes) > 0,
        genes.to.label = highlightGenes
      )
      myplot
    })
    output[['ma']] <- renderPlot(ma.plot())
    
    scatter.plot <- reactive({
      sub.expression.matrix <- expression.matrix()[,c(input[["scatter_sample1"]],
                                                      input[["scatter_sample2"]])]
      myplot <- scatter_plot(sub.expression.matrix,
                             anno,
                             input[["scatterGeneName"]])
      myplot
    })
    output[['scatter']] <- renderPlot(scatter.plot())
    
    density.plot <- reactive({
      myplot <- qc_density_plot(
        expression.matrix = expression.matrix(),
        metadata = metadata(),
        annotation.id = input[['density.annotation']])
      myplot
    })
    output[['density']] <- renderPlot(density.plot())
    
    violin.plot <- reactive({
      myplot <- qc_violin_plot(
        expression.matrix = expression.matrix(),
        metadata = metadata(),
        annotation.id = input[['violin.annotation']],
        log.transformation = input[['violin.log.transformation']])
      myplot
    })
    output[['violin']] <- renderPlot(violin.plot())
    
    bar.plot <- reactive({
      gene.ids <- anno$ENSEMBL[match(input[["barGeneName"]],anno$NAME)]
      if (length(gene.ids)==1){
        sub.expression.matrix <- t(data.frame(expression.matrix()[gene.ids,]))
      } else {
        sub.expression.matrix <- (data.frame(expression.matrix()[gene.ids,]))
      }
      rownames(sub.expression.matrix) <- input[["barGeneName"]]
      myplot <- genes_barplot(
        sub.expression.matrix = sub.expression.matrix,
        log.transformation = input[['bar.log.transformation']])
      myplot
    })
    output[['barplot']] <- renderPlot(bar.plot())
    
    output[['downloadJSIPlot']] <- downloadHandler(
      filename = function() { input[['plotJSIFileName']] },
      content = function(file) {
        if (base::strsplit(input[['plotJSIFileName']], split="\\.")[[1]][-1] == 'pdf'){
          grDevices::pdf(file)
          print(jaccard.plot())
          grDevices::dev.off()
        } else if (base::strsplit(input[['plotJSIFileName']], split="\\.")[[1]][-1] == 'svg'){
          grDevices::svg(file)
          print(jaccard.plot())
          grDevices::dev.off()
        } else {
          grDevices::png(file)
          print(jaccard.plot())
          grDevices::dev.off()
        }
      }
    )
    
    output[['downloadPCAPlot']] <- downloadHandler(
      filename = function() { input[['plotPCAFileName']] },
      content = function(file) {
        ggsave(file, plot = pca.plot(), dpi = 300)
      }
    )
    
    output[['downloadMAPlot']] <- downloadHandler(
      filename = function() { input[['plotMAFileName']] },
      content = function(file) {
        ggsave(file, plot = ma.plot(), dpi = 300)
      }
    )
    
    output[['downloadScatterPlot']] <- downloadHandler(
      filename = function() { input[['plotScatterFileName']] },
      content = function(file) {
        ggsave(file, plot = scatter.plot(), dpi = 300)
      }
    )
    
    output[['downloadDensityPlot']] <- downloadHandler(
      filename = function() { input[['plotDensityFileName']] },
      content = function(file) {
        ggsave(file, plot = density.plot(), dpi = 300)
      }
    )
    
    output[['downloadBarPlot']] <- downloadHandler(
      filename = function() { input[['plotBarFileName']] },
      content = function(file) {
        ggsave(file, plot = bar.plot(), dpi = 300)
      }
    )
    
  })
}

# QCpanelApp <- function(){
#   shinyApp(
#     ui = fluidPage(QCpanelUI('qc', metadata)),
#     server = function(input, output, session){
#       QCpanelServer('qc', expression.matrix, metadata)
#     }
#   )
# }