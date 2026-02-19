library(btw)
library(ellmer)
library(shinychat)
library(ggbeeswarm)

options(btw.run_r.enabled = TRUE)
Sys.setenv(ANTHROPIC_API_KEY = readLines("api-key.txt"))

btw_app(
  client = ellmer::chat_anthropic(
    system_prompt = readLines("btw.md")
  ),
  tools = btw_tools(),
  messages = list("**Hello!** I am the ggbeeswarm bot. How can I help you today?")
)