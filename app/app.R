library(shiny)
library(tidyverse)
library(ngram)

# Load the model
load("list_dic2.data")
load("list_dic3.data")
dic2 <- as.environment(list_dic2)
dic3 <- as.environment(list_dic3)
rm(list_dic2, list_dic3)

process <- function(s) {
    s <- preprocess(s, remove.punct = TRUE)
    s <- str_split(s, " ")[[1]]
    paste(s[length(s) - 1], s[length(s)])
}

f <- function(context) {
    if (context %in% c("", " ")) {
        return(c("the", "to", "a", "and", "of")) 
    }
    if (!exists(context, dic3)) {
        context <- str_split(context, " ")[[1]][2]
        if (!exists(context, dic2)) {
            return(c("the", "to", "a", "and", "of")) 
        }
        x <- dic2[[context]]$prediction
        while (length(x) < 5) {
            x <- c(x, "")
        }
        return(x)
    }
    x<- dic3[[context]]$prediction
    while (length(x) < 5) {
        x <- c(x, "")
    }
    x
}

next_word <- function(text) {
    f(process(text))
}

ui <- fluidPage(
    h1("Tweet Helper"),
    p("This app tries to guess what you will type next. Type into the box, and suggested words will appear on the buttons."),
    p("Click a button to add the word to the box. Click and drag the bottom right corner of the box to expand it."),
    p("The app is based on data from 100,000 randomly selected tweets."),
    textAreaInput("text_box", "", value = ""),
    actionButton("button1", ""),
    actionButton("button2", ""),
    actionButton("button3", ""),
    actionButton("button4", ""),
    actionButton("button5", "")
)

server <- function(input, output, session) {

    p <- NULL
    
    observeEvent(input$text_box, {
        p <<- next_word(input$text_box)
        updateActionButton(session, "button1", label = p[1])
        updateActionButton(session, "button2", label = p[2])
        updateActionButton(session, "button3", label = p[3])
        updateActionButton(session, "button4", label = p[4])
        updateActionButton(session, "button5", label = p[5])
    })
    
    observeEvent(input$button1, {
        text <- input$text_box
        new_text <- paste(text, p[1])
        updateTextAreaInput(session, "text_box", value = new_text)
    })
    
    observeEvent(input$button2, {
        text <- input$text_box
        new_text <- paste(text, p[2])
        updateTextAreaInput(session, "text_box", value = new_text)
    })
    
    observeEvent(input$button3, {
        text <- input$text_box
        new_text <- paste(text, p[3])
        updateTextAreaInput(session, "text_box", value = new_text)
    })
    
    observeEvent(input$button4, {
        text <- input$text_box
        new_text <- paste(text, p[4])
        updateTextAreaInput(session, "text_box", value = new_text)
    })
    
    observeEvent(input$button5, {
        text <- input$text_box
        new_text <- paste(text, p[5])
        updateTextAreaInput(session, "text_box", value = new_text)
    })
}

shinyApp(ui = ui, server = server)