library(shiny)
library(shinychat)

Sys.setenv(ANTHROPIC_API_KEY = readLines("api-key.txt"))

ui <- bslib::page_fillable(
  chat_ui(
    id = "chat",
    messages = "**Hello!** How can I help you today?"
  ),
  fillable_mobile = TRUE
)

server <- function(input, output, session) {
  chat <-
    ellmer::chat_anthropic(
      system_prompt = readLines("btw.md")
    )
  
  observeEvent(input$chat_user_input, {
    stream <- chat$stream_async(input$chat_user_input)
    chat_append("chat", stream)
  })
}

shinyApp(ui, server)