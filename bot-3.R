library(shiny)
library(btw)
library(ellmer)
library(bslib)
library(shinychat)
library(ggbeeswarm)

options(btw.run_r.enabled = TRUE)

# --- Read API key -------------------------------------------------------------
api_key <- trimws(readLines("api-key.txt", n = 1))
Sys.setenv(ANTHROPIC_API_KEY = api_key)

# --- Custom code-execution tool that captures plots --------------------------
#
# We replace btw's built-in "code" tool with our own version that:
#   1. Runs the code
#   2. Captures any plot to a temp PNG
#   3. Returns the text output AND the image as a base64 data URI,
#      which shinychat will render inline in the chat bubble.

r_exec_with_plot <- ellmer::tool(
  name        = "r_exec_with_plot",
  description = paste(
    "Execute R code in the user's session.",
    "Returns printed output and, if a plot was produced, the plot image.",
    "Always show the code you are running in your reply using a ```r block."
  ),
  fun = function(code) {

    # Capture text output
    txt <- utils::capture.output({
      tmp_png <- tempfile(fileext = ".png")
      grDevices::png(tmp_png, width = 800, height = 500, res = 120)
      on.exit({
        grDevices::dev.off()
        if (file.exists(tmp_png)) file.remove(tmp_png)
      }, add = TRUE)

      tryCatch(
        eval(parse(text = code), envir = globalenv()),
        error = function(e) cat("Error:", conditionMessage(e), "\n")
      )
    })

    grDevices::dev.off()   # flush the PNG device before reading

    result <- paste(txt, collapse = "\n")

    # If a plot was written, embed it as a markdown image data URI
    if (file.exists(tmp_png) && file.info(tmp_png)$size > 0) {
      b64 <- base64enc::base64encode(tmp_png)
      img_md <- sprintf("![plot](data:image/png;base64,%s)", b64)
      result  <- if (nzchar(result)) paste(result, img_md, sep = "\n\n") else img_md
    }

    result
  },
  arguments = list(
    code = ellmer::type_string("Valid R code to execute.")
  )
)

# --- UI ----------------------------------------------------------------------
ui <- page_fillable(
  fillable_mobile = TRUE,
  title = "R Assistant",
  card(
    card_header("R Assistant — powered by Claude + btw"),
    chat_ui("chat", height = "100%"),
    full_screen = TRUE
  )
)

# --- Server ------------------------------------------------------------------
server <- function(input, output, session) {

  chat_client <- chat_anthropic(
    model         = "claude-sonnet-4-20250514",
    system_prompt = paste(
      "You are a helpful R programming assistant with access to the user's",
      "live R session.",
      "",
      "When you write or run code, ALWAYS:",
      "  1. Show the complete code in a ```r fenced block in your reply.",
      "  2. Call the r_exec_with_plot tool to run it.",
      "  3. Display the tool's output (including any plot image) in your reply.",
      "",
      "Use btw tools to inspect the environment, session, docs, or files",
      "whenever relevant."
    )
  )

  # Register btw tools except its built-in code runner (we use ours instead)
  chat_client$register_tools(btw_tools(c("env", "session", "docs", "files")))

  # Register our plot-aware code execution tool
  chat_client$register_tools(list(r_exec_with_plot))

  observeEvent(input$chat_user_input, {
    stream <- chat_client$stream_async(input$chat_user_input)
    chat_append("chat", stream)
  })
}

shinyApp(ui, server)