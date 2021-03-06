require(shiny)
 
shinyUI(pageWithSidebar(
 
     headerPanel("Home Automation Data Model - TV"),
     
     sidebarPanel(
         
         wellPanel(
             selectInput(inputId = "x_var",
                         label = "X variable",
                         choices = c("Temperature (Celcius)" = "Temp", "Humidity (Percentage)" = "Hum", "Hours" = "Hrs"),
                         selected = "Temperature"
                         ),
 
             uiOutput("x_range_slider")
         ),
         
           
         wellPanel(
             selectInput(inputId = "y_var",
                         label = "Y variable",
                         choices = c("Breakdowns (Yes/No)" = "y"),
                         ),
             
             uiOutput("y_range_slider")
         ),
         
           
         wellPanel(
             p(strong("Model predictions")),
             checkboxInput(inputId = "mod_logistic",    label = "Logistic (dot-dash)"),
             conditionalPanel(
                 condition = "input.mod_loess == true",
                 sliderInput(inputId = "mod_loess_span", label = "Smoothing (alpha)",
                     min = 0.15, max = 1, step = 0.05, value = 0.75)
             )
         )
     ),
     
     mainPanel(
         plotOutput(outputId = "main_plot"),
         
         conditionalPanel("input.mod_logistic == true",
             p(strong("Logit model")),
             verbatimTextOutput(outputId = "mod_logistic_text")
         ),
     )     
  ))

library(ggplot2)

hw <- read.csv("LogitTV.csv")

in_range <- function(x, range) {
  x >= min(range) & x <= max(range)
  
}

shinyServer(function(input, output) {
  
  limit_data_range <- function() {
    
    if (is.null(input$x_range) || is.null(input$y_range)) {
      return(NULL)
    }
    
    hw_sub <- hw[in_range(hw[[input$x_var]], input$x_range) &
                   in_range(hw[[input$y_var]], input$y_range), ]
    
    hw_sub
  }
  
  
  
  output$main_plot <- renderPlot({
    
    
    hw_sub <- limit_data_range()
    
    if (is.null(hw_sub))
      return()
    
    
    xdat <- hw[[input$x_var]]
    ydat <- hw[[input$y_var]]
    
    
    
    
    
    if(input$mod_logistic)
      point_alpha <- 0.5  
    else
      point_alpha <- 1
    
    
    
    
    
    
    p <- ggplot(hw_sub, mapping = aes_mapping) +
      points +
      theme_bw() +
      scale_colour_hue(l = 40) +
      scale_shape(solid = FALSE) +
      
      scale_x_continuous(limits = range(xdat)) +
      scale_y_continuous(limits = range(ydat))
    
    
    
    
    if (max(input$x_range) != max(xdat)) {
      p <- p + geom_vline(xintercept = max(input$x_range), linetype = "dashed",
                          alpha = 0.3)
    }
    if (min(input$x_range) != min(xdat)) {
      p <- p + geom_vline(xintercept = min(input$x_range), linetype = "dashed",
                          alpha = 0.3)
    }
    
    if (max(input$y_range) != max(ydat)) {
      p <- p + geom_hline(yintercept = max(input$y_range), linetype = "dashed",
                          alpha = 0.3)
    }
    if (min(input$y_range) != min(ydat)) {
      p <- p + geom_hline(yintercept = min(input$y_range), linetype = "dashed",
                          alpha = 0.3)
    }
    
    
    if (input$mod_logistic) {
      p <- p + geom_smooth(method = lm, se = FALSE, size = 0.75,    
                           linetype = "dotdash")
    }
    
    print
  })
  
  
  
  output$x_range_slider <- renderUI({
    xmin <- floor(min(hw[[input$x_var]]))
    xmax <- ceiling(max(hw[[input$x_var]]))
    
    sliderInput(inputId = "x_range",
                label = paste("Limit range"),
                min = xmin, max = xmax, value = c(xmin, xmax))
  })
  
  output$y_range_slider <- renderUI({
    ymin <- floor(min(hw[[input$y_var]]))
    ymax <- ceiling(max(hw[[input$y_var]]))
    
    sliderInput(inputId = "y_range",
                label = paste("Limit range"),
                min = ymin, max = ymax, value = c(ymin, ymax))
  })
  
  
  
  
  
  make_model <- function(model_type, formula, ...) {
    
    hw_sub <- limit_data_range()
    if (is.null(hw_sub))
      return()
    
    
    
    do.call(model_type, args = list(formula = formula, data = quote(hw_sub), ...))
  }
  
  output$mod_logistic_text <- renderPrint({
    formula <- paste(input$y_var, "~", input$x_var)
    
  })
runApp("~/LogitTV.R", port=8100)