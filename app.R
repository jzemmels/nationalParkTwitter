#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)
library(tidyverse)
library(leaflet)

# no longer read in shp file. we have a simplified version of the geometry that
# takes up considerably less memory

# npsBoundaries <- sf::read_sf("data/nps_boundary/nps_boundary.shp") %>%
#   filter(UNIT_TYPE %in% c("National Monument","National Historic Site","National Historical Park","National Park",
#                           "National Memorial","National Preserve","National Recreation Area","National Battlefield",
#                           "National Seashore","National Battlefield Park","National River","Other Designation")) %>%
#   sf::st_transform(sp::CRS("+proj=longlat +datum=WGS84 +no_defs")) %>%
#   arrange(UNIT_NAME)

load("data/npsBoundaries_simplified.RData")
load("data/parkNameTwitterLinks.RData")

# leaflet map will have a border if the park has a twitter account
npsBoundaries_simplified <- npsBoundaries_simplified %>%
  sf::st_as_sf() %>%
  left_join(parkNameTwitterLinks,by = c("UNIT_NAME")) %>%
  mutate(hasTwitter = ifelse(is.na(accountLink),FALSE,TRUE))

# Define UI for application that draws a histogram
ui <-
  # dashboardPage(
  fluidPage(
    shinybusy::add_busy_spinner(),

    # Application title
    titlePanel("Click on a national park to view its Twitter feed"),
    sidebarPanel(width = 2,
                 selectInput(inputId = "selectedParks",
                             label = "Select Parks",
                             choices = unique(npsBoundaries_simplified$UNIT_NAME),
                             selected = NULL,
                             multiple = TRUE)
    ),

    # Show a plot of the generated distribution
    mainPanel(
      column(width = 8,leafletOutput("npsMap",height = 750)),
      column(width = 4,
             htmlOutput(outputId = "twitterFeed")
      )
    )
  )

# Define server logic required to draw a histogram
server <- function(session,input, output) {

  pal <- colorFactor("Set3",domain = NULL)

  output$npsMap <- renderLeaflet({

    leaflet() %>%
      setView(-98.483330, 38.712046, zoom = 4) %>%
      addTiles() %>%
      addPolygons(data = npsBoundaries_simplified,
                  weight = 2,
                  color = "black",
                  fillOpacity = .8,
                  stroke = ~npsBoundaries_simplified$hasTwitter,
                  fillColor = ~pal(npsBoundaries_simplified$UNIT_TYPE),
                  label = npsBoundaries_simplified$UNIT_NAME,
                  layerId = ~npsBoundaries_simplified$UNIT_NAME) %>%
      addLegend(pal = pal,values = unique(npsBoundaries_simplified$UNIT_TYPE),position = "bottomright",title = NULL,opacity = .8)

  })

  observeEvent(input$npsMap_shape_click,{

    currentlySelected <- input$selectedParks

    updateSelectInput(session = session,
                      inputId = "selectedParks",
                      selected = input$npsMap_shape_click$id)

  })

  feedString <- reactiveVal("")

  observeEvent(input$selectedParks,{

    req(input$selectedParks)

    selectedParkTwitters <- parkNameTwitterLinks %>%
      filter(UNIT_NAME %in% input$selectedParks) %>%
      pull(accountLink) %>%
      str_remove_all('\"')

    req(length(selectedParkTwitters) > 0)


    feedString(selectedParkTwitters)

  })

  observe({

    twitterFeed <- feedString()

    req(str_length(twitterFeed) > 0)

    output$twitterFeed <- renderUI({

      return(tagList(
        # twitter timeline needs to update if the user selects a new park. these
        # functions auto-refresh the element every second, from:
        # https://stackoverflow.com/questions/28495525/auto-refresh-twitter-timeline-widget-every-30-seconds
        tags$script('window.twttr = (function (d,s,id) {

    var t, js, fjs = d.getElementsByTagName(s)[0];
    if (d.getElementById(id)) return; js=d.createElement(s); js.id=id;
    js.src="https://platform.twitter.com/widgets.js";
    fjs.parentNode.insertBefore(js, fjs);

    return window.twttr || (t = { _e: [], ready: function(f){ t._e.push(f) } });

}(document, "script", "twitter-wjs"));

twttr.ready(function (twttr) {

    twttr.widgets.load();
    setInterval(function() {
        twttr.widgets.load();
        console.log("update twitter timeline each second");
    }, 1000);

})'),
tags$a(twitterFeed, class="twitter-timeline"
       , href = twitterFeed)))


    })

  })


}

# Run the application
shinyApp(ui = ui, server = server)
