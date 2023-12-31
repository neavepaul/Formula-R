"****
Loading the libraries required to run the dashboard
****"
library(shiny)
library(ggplot2)
library(ggthemes)
library(readxl)
library(dplyr)
library(shinythemes)
library(HH)
library(plotly)
library(alluvial)
library(ggalluvial)
library(scales)
library(plotly)
library(data.table)

"****
Loading the dataset required for the dashboard
****"
F1_data <- read_xlsx("F1_data.xlsx")
pit_stop <- read_excel('pit_stop_2017.xlsx')
pie_data <- read_xlsx('Wins.xlsx')
barplot_data <-pie_data[,c('Driver','Wins','Races')]
sankey_data <- read_xlsx('Team_Driver.xlsx')

barplot_table <- data.table(barplot_data)
pie_table <- data.table(pie_data)

"****
Defining the User Interface of the shiny app
1. Page-1:
a. It contains a TabPanel which has :
Range Slider - for the year
Dropdown - list all the drivers name
b. It contains a Main Panel:
Sankey chart
Bar chart
Pie Chart

2. Page-2:
a. It contains a TabPanel which has :
Dropdown - list all the circuits
b. It contains a Main Panel:
GGplot chart(Line chart)
GGplot chart(Heatmap)

****"
ui <- navbarPage("F1 Analysis",
                 tabPanel("Page 1",
                          sidebarLayout(
                            sidebarPanel(
                              sliderInput(inputId = "year", "Choose the year range",
                                          min = 1950, max = 2017,
                                          value = c(1975,1985)),
                              selectInput(inputId = 'drivers', label = 'Choose a Driver', c('SCHUMACHER'='SCHUMACHER Michael','HAMILTON'='HAMILTON Lewis','VETTEL' = 'VETTEL Sebastian','PROST'='PROST Alain',
                                                                                            'SENNA' = 'SENNA Ayrton',
                                                                                            'ALONSO' = 'ALONSO Fernando',
                                                                                            'MANSELL' = 'MANSELL Nigel',
                                                                                            'STEWART' = 'STEWART Jackie','CLARK' = 'CLARK Jim',
                                                                                            'LAUDA'='LAUDA Niki',
                                                                                            'PIQUET' = 'PIQUET Nelson',
                                                                                            'ROSBERG' = 'ROSBERG Nico',
                                                                                            'HILL D' = 'HILL Damon',
                                                                                            'RAIKKONEN' = 'RAIKKONEN Kimi',
                                                                                            'SHAKKINEN' = 'HAKKINEN Mika',
                                                                                            'MOSS' = 'MOSS Stirling','United States Grand Prix'='BUTTON Jenson',
                                                                                            'HILL G'='HILL Graham',
                                                                                            'BRABHAM' = 'BRABHAM Jack',
                                                                                            'BOTTAS' = 'BOTTAS Valtteri'),multiple = TRUE, selected = c('SCHUMACHER'='SCHUMACHER Michael'))
                            ),
                            mainPanel(
                              tags$h3("Examining the relation with driver and team with the wins comparison"),
                              tags$p("The Sankey chart represents the relationship between the teams and the drivers. Based on the year range (provided in the left panel), it shows the drivers relationship with respect to the teams."),
                              textOutput("yeartext"),
                              plotOutput(outputId = 'Sankeyplot'),
                              tags$p("The Bar chart represents the selected drivers (from the dropdown provided in the left panel) races and plot the wins and the races of the drivers."),
                              textOutput("drivertext"),
                              plotOutput(outputId = 'Barplot'),
                              # verbatimTextOutput("dfStr"),
                              tags$p("The Pie chart represents the selected drivers (from the dropdown provided in the left panel) wins among each other."),
                              plotOutput(outputId = 'Pieplot')
                              
                            )
                          )
                 ),
                 tabPanel("Page 2",
                          sidebarLayout(
                            sidebarPanel(
                              selectInput(inputId = 'circuits', label = 'Choose a Circuit', c('Bahrain Grand Prix'='971','Australian Grand Prix'='969','Malaysian Grand Prix' = '983','Russian Grand Prix'='972',
                                                                                              'Chinese Grand Prix' = '970',
                                                                                              'Spanish Grand Prix' = '973',
                                                                                              'Monaco Grand Prix' = '974',
                                                                                              'Canadian Grand Prix' = '975','Azerbaijan Grand Prix' = '976',
                                                                                              'Austrian Grand Prix'='977',
                                                                                              'British Grand Prix' = '978',
                                                                                              'Hungarian Grand Prix' = '979',
                                                                                              'Belgian Grand Prix' = '980',
                                                                                              'Italian Grand Prix' = '981',
                                                                                              'Singapore Grand Prix' = '982',
                                                                                              'Japanese Grand Prix' = '984','United States Grand Prix'='985',
                                                                                              'Mexican Grand Prix'='986',
                                                                                              'Brazilian Grand Prix' = '987',
                                                                                              'Abu Dhabi Grand Prix' = '988'))
                            ),
                            mainPanel(
                              tags$h3("Lap Analysis of drivers"),
                              tags$p("The multiple line chart represents the respective positions of the drivers on the particular laps which will be easy to identify the status of the driver positions."),
                              plotlyOutput(outputId = 'lap_plot'),
                              tags$p("The heatmap chart represents the respective pitstop of the drivers on the particular laps."),
                              plotlyOutput(outputId = 'pit_analysis')
                            )
                          )
                 )
)

"****
Defining the server for the shiny app
****"
server <- function(input, output){
  
  output$yeartext <- renderText(paste0('The selected year range is between ',input$year[1],' and ',input$year[2]))
  output$drivertext <- renderText(paste0(input$drivers))
  
  "****
  Plotting the ggplot chart with respect to the laps and positions of the driver for the selected race from the UI dropdown
  ****"
  output$lap_plot <- renderPlotly({
    ggplot(F1_data[F1_data$raceId == input$circuits, ], aes(x=lap,y=position, colour = driverRef)) + geom_line(size=0.5) +
      guides(color = FALSE) + scale_x_continuous(breaks = scales::pretty_breaks(5)) +
      ggtitle("Lap Chart")
  })
  
  "****
  Plotting the ggplot chart with respect to the driverRef and lap of the driver for the selected race from the UI dropdown
  ****"
  output$pit_analysis <- renderPlotly({
    ggplot(data = pit_stop[pit_stop$raceId == input$circuits,], aes(x = lap, y = driverRef)) +
      geom_tile(aes(fill = seconds), colour = 'white')+scale_fill_gradient(low = "orange",high = "orangered4")+
      theme_bw(base_size = 10) + ggtitle("PitStop Analysis")
  })
  
  "****
  Plotting the Sankey chart with respect to the Teams and Drivers from the data
  ****"
  output$Sankeyplot <- renderPlot({
    ggplot(sankey_data[sankey_data$Season >= input$year[1] & sankey_data$Season <= input$year[2],],
           aes( axis1 = Constructor, axis2 = Drivers)) +
      geom_alluvium(aes(fill = Constructor), width = 1/12) +
      geom_stratum(width = 1/5, fill = "black", color = "grey") +
      geom_label(stat = "stratum", label.strata = T) +
      scale_x_discrete(limits = c("Teams", "Drivers"), expand = c(.5, .05))
  })
  
  "****
  Plotting the Bar chart with respect to the race count and the wins of the drivers selected from the UI dropdown from the data
  ****"
  output$Barplot <- renderPlot({
    likert(barplot_table[Driver %in% input$drivers], horizontal = T,ylab = 'Drivers',
           main = 'Wins Vs Race', # or give "title", # becomes ylab due to horizontal arg
           auto.key = list(space = "right", columns = 1,
                           reverse = TRUE))
  })
  
  "****
  Plotting the Pie chart with respect to the wins of the drivers selected from the UI dropdown
  ****"
  output$Pieplot <- renderPlot({
    ggplot(pie_table[Driver %in% input$drivers], aes(x="", y=Wins, fill=Driver))+
      geom_bar(width = 1, stat = "identity") +
      coord_polar("y", start=0) +
      geom_text(aes(y = Wins/3 + c(0, cumsum(Wins)[-length(Wins)]),
                    label = percent(Wins/100)), size=5)
  })
}

"****
Starting the shiny app by passing the UI and the server created above
****"
shinyApp(ui = ui, server = server)
