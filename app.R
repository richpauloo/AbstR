# load packages
# devtools::install_github("nstrayer/shinysense")
library(shiny)
library(shinysense)
library(data.table)
library(dplyr)
library(DT)

# set wd
# setwd('/Users/richpauloo/Desktop/AGU API')

# bring in cleaned 2016 data
dat <- fread("dat_2016.csv")

# Define UI for App ----
ui <- fluidPage(
  
  # App Title -----
  titlePanel("AbstR"),
  
  # App Description ----
  p("More than 20,000 presentations will occur at AGU this week, and they're all in AbstR. AbstR helps you discover research based on what you input in the checkboxes to your left. Swipe RIGHT to save interesting abstracts. Swipe LEFT to discard uninteresting research."),
  
    # Sidebar panel for Inputs ----
    sidebarPanel(
    
      h4(strong("Filter Abstracts")),
      
      # Horizontal line ----
      tags$hr(),
      
      # Title for CheckBox Group 1: Days of Week ----
      h4("Select Day(s):"),
      
        # Input Days ----
        checkboxGroupInput("ab_day_of_week", 
                           label = NULL, 
                           choices = c("Monday" = "Monday",
                                       "Tuesday" = "Tuesday",
                                       "Wednesday" = "Wednesday",
                                       "Thursday" = "Thursday",
                                       "Friday" = "Friday"),
                           selected = "Monday"),
    
      # # Horizontal line ----
      tags$hr(),

      # Title for CheckBox Group 2: Time of Day ----
      h4("Select Time(s):"),

        # Input Time of Day ----
        checkboxGroupInput("ab_morn_aft",
                           label = NULL,
                           choices = c("Morning" = "Morning",
                                       "Afternoon" = "Afternoon"),
                           selected = c("Morning", "Afternoon")),

      # Horizontal line ----
      tags$hr(),
      
      # Title for CheckBox Group 3: Poster or Talk ----
      h4("Select Type(s):"),
        
        # Input isPoster ----
        checkboxGroupInput("isPoster", 
                           label = NULL, 
                           choices = c("Poster" = "Poster",
                                       "Oral" = "Oral"),
                           selected = c("Poster", "Oral")),
      
      # Horizontal line ----
      tags$hr(),
      
      # Title for CheckBox group 4: Section ----
      h4("Select Section(s):"),
      
        # Input Interests ---- 
        checkboxGroupInput("section", 
                           label = NULL, 
                           choices = c("Union" = "Union",
                                       "Atmospheric Sciences" = "Atmospheric Sciences",
                                       "Biogeosciences" = "Biogeosciences",
                                       "Cryosphere" = "Cryosphere",
                                       "Geodesy" = "Geodesy",
                                       "Hydrology" = "Hydrology", 
                                       "Planetary Sciences" = "Planetary Sciences", 
                                       "Tectonophysics" = "Tectonophysics",
                                       "Volcanology, Geochemistry and Petrology" = "Volcanology, Geochemistry and Petrology", 
                                       "Seismology" = "Seismology", 
                                       "Atmospheric and Space Electricity" = "Atmospheric and Space Electricity",
                                       "Earth and Planetary Surface Processes" = "Earth and Planetary Surface Processes", 
                                       "Earth and Space Science Informatics" = "Earth and Space Science Informatics",
                                       "Education" = "Education",
                                       "Geomagnetism, Paleomagnetism and Electromagnetism" = "Geomagnetism, Paleomagnetism and Electromagnetism",
                                       "Global Environmental Change" = "Global Environmental Change", 
                                       "Mineral and Rock Physics" = "Mineral and Rock Physics",
                                       "Natural Hazards" = "Natural Hazards", 
                                       "Nonlinear Geophysics" = "Nonlinear Geophysics",
                                       "Near Surface Geophysics" = "Near Surface Geophysics", 
                                       "Ocean Sciences" = "Ocean Sciences",
                                       "Paleoceanography and Paleoclimatology" = "Paleoceanography and Paleoclimatology", 
                                       "Public Affairs" = "Public Affairs", 
                                       "SPA-Aeronomy" = "SPA-Aeronomy",
                                       "SPA-Magnetospheric Physics" = "SPA-Magnetospheric Physics", 
                                       "SPA-Solar and Heliospheric Physics" = "SPA-Solar and Heliospheric Physics",
                                       "Study of Earth's Deep Interior" = "Study of Earth's Deep Interior"),
                           selected = c("Union", "Atmospheric Sciences", "Biogeosciences")
    )
),
    # Define the main Panel ----
    mainPanel(
      tabsetPanel(
        tabPanel("Explore Abstracts",
                 shinyswipr::shinyswiprUI( "quote_swiper",
                        h4("Swipe Me!"),
                        hr(),
                        
                        # abstract info ----
                        h4("Title:"),
                        textOutput("quote_title"),
                        h4("Abstract:"),
                        textOutput("quote"),
                        h4("Presenter:"),
                        textOutput("quote_author"),
                        h4("Time and Location:"),
                        textOutput("quote_when"),
                        h4("Paper Number:"),
                        textOutput("quote_num"),
                        h4("Presentation Type:"),
                        textOutput("quote_type"),
                        
                        # section / session info ----
                        hr(),
                        h4("Section:"),
                        textOutput("section"),
                        h4("Session Number and Title:"),
                        textOutput("ses_title"),
                        h4("Session Time and Location:"),
                        textOutput("ses_when")
                       )
        ),
        tabPanel("Swipe History",
                        # previous swipes ----
                        h4("Swipe History"),
                        DT::dataTableOutput("resultsTable")
          )
        )
      )
)


# Define Server for App ----
server <- function(input, output) {

  # Define Module
  card_swipe <- callModule(shinyswipr, "quote_swiper")
  
  # Define appVals
  init <- sample_n(dat, 1) %>% as.list()
  appVals <- reactiveValues(
    quote = init,
    swipes = data.frame( title = character(), 
                         author = character(), 
                         time = character(),
                         location = character(),
                         paperID = character(),
                         swipe = character())
  )
  
  # Generate Output
  our_quote <- isolate(appVals$quote)
  output$quote_title <- renderText({ our_quote$abstract_title })
  output$quote <- renderText({ our_quote$abstract_text })
  output$quote_author <- renderText({ paste(our_quote$lastName, our_quote$firstName, sep=", ") })
  output$resultsTable <- renderDataTable({ appVals$swipes })
  colnames(dat)
  # Observe Event ----
  observeEvent( card_swipe(),{
    #Record our last swipe results.
    appVals$swipes <- rbind(
      data.frame( title = appVals$quote$abstract_title,
                  author = appVals$quote$lastName,
                  paperID = appVals$quote$finalPaperNumber,
                  time = paste(
                         paste(appVals$quote$ab_day_of_week, 
                               appVals$quote$abstract_startTime, sep = " "),
                               appVals$quote$abstract_endTime, sep = " - "),
                  location = paste(appVals$quote$abstract_room_name, 
                                   appVals$quote$ab_building, sep = " "),
                  swipe = card_swipe()
      ), appVals$swipes
    )
    #send results to the output.
    output$resultsTable <- DT::renderDataTable({ appVals$swipes })
    glimpse(dat)
    #update the quote
    temp <- dat %>% filter(ab_day_of_week %in% input$ab_day_of_week & 
                             isPoster %in% input$isPoster & 
                             section %in% input$section & 
                             ab_morn_aft %in% input$ab_morn_aft) 
    appVals$quote <- sample_n(temp, 1) %>% as.list()
    
    #send update to the ui.
    output$quote_title <- renderText({ appVals$quote$abstract_title })
    
    output$quote_num <- renderText({ appVals$quote$finalPaperNumber })
    
    output$quote <- renderText({ appVals$quote$abstract_text })
    
    output$quote_author <- renderText({ paste(appVals$quote$lastName, 
                                              appVals$quote$firstName, sep=", ") })
    
    output$quote_when <- renderText({ paste(
                                      paste(
                                      paste(
                                      paste(appVals$quote$ab_day_of_week, 
                                            appVals$quote$abstract_startTime, sep = "  /  "),
                                            appVals$quote$abstract_endTime, sep = " - "),
                                            appVals$quote$ab_building, sep = "  /  "),
                                            appVals$quote$abstract_room_name, sep = " ") })
    
    output$quote_type <- renderText({ appVals$quote$isPoster })
    
    output$section <- renderText({ appVals$quote$section })
    
    output$ses_title <- renderText({ paste(
                                     paste(
                                     paste("(",
                                           appVals$quote$finalSessionNumber, sep=""),
                                           ")", sep = ""),
                                           appVals$quote$session_title, sep = " ") })
    
    output$ses_when <- renderText({ paste(
                                    paste(
                                    paste(
                                    paste(appVals$quote$ses_day_of_week, 
                                          appVals$quote$session_startTime, sep = "  /  "),
                                          appVals$quote$session_endTime, sep = " - "),
                                          appVals$quote$ses_building, sep = "  /  "),
                                          appVals$quote$session_room_name, sep = " ") })
  }) #close event observe.
  
}

# Run the App ----
shinyApp(ui, server)
