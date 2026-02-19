library(shiny)
library(btw)
library(ellmer)
library(bslib)
library(shinychat)
library(ggbeeswarm)

options(btw.run_r.enabled = TRUE)

# --- Read API key from file ---------------------------------------------------
api_key <- trimws(readLines("api-key.txt", n = 1))
Sys.setenv(ANTHROPIC_API_KEY = api_key)

# --- UI -----------------------------------------------------------------------
ui <- page_fillable(
  fillable_mobile = TRUE,
  title = "R Assistant",
  card(
    card_header("R Assistant — powered by Claude + btw"),
    chat_ui("chat", height = "100%"),
    full_screen = TRUE
  )
)

# --- Server -------------------------------------------------------------------
server <- function(input, output, session) {

  # Create a fresh chat client per user session
  chat_client <- chat_anthropic(
    model         = "claude-sonnet-4-5-20250929",
    system_prompt = readLines("btw.md")
  )

  # Register ALL btw tools:
  #   "env"     – list/describe objects in the global environment
  #   "session" – R version, loaded packages, platform info
  #   "docs"    – look up R help pages and package documentation
  #   "files"   – read files in the working directory
  #   "code"    – execute R code and return results  (powerful – use carefully!)
  chat_client$register_tools(btw_tools())
  # Or be selective, e.g.:
  #   chat_client$register_tools(btw_tools(c("env", "session", "code")))

  # Stream user messages to the model and pipe the reply back into the UI
  observeEvent(input$chat_user_input, {
    stream <- chat_client$stream_async(input$chat_user_input)
    chat_append("chat", stream)
  })
}

shinyApp(ui, server)