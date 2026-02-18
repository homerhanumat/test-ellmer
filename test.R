Sys.setenv(ANTHROPIC_API_KEY = readLines("api-key.txt"))
library(ellmer)

chat <- chat_anthropic()
live_console(chat)
chat$get_tokens()

library(btw)
library(beeswarm)
use_btw_md(scope = "project")
btw(beeswarm::beeswarm)

library(rdocdump)
rdd_to_txt(
  pkg = "ggbeeswarm",
  file = "context.txt",
  force_fetch = FALSE # Set to TRUE to redownload from CRAN
)

library(ggplot2)
library(ggbeeswarm)

# Create an impressive multi-layered beeswarm plot
ggplot(iris, aes(x = Species, y = Petal.Length, color = Sepal.Width)) +
  # Add beeswarm points with color gradient
  geom_beeswarm(
    cex = 3,
    size = 3,
    alpha = 0.7,
    priority = "density"
  ) +
  # Add a subtle boxplot in background
  geom_boxplot(
    aes(group = Species),
    alpha = 0.2,
    outlier.shape = NA,
    color = "gray30",
    fill = NA
  ) +
  # Customize colors with a beautiful gradient
  scale_color_viridis_c(option = "plasma") +
  # Add labels and theme
  labs(
    title = "Iris Petal Length Distribution by Species",
    subtitle = "Beeswarm plot showing individual measurements colored by sepal width",
    x = "Species",
    y = "Petal Length (cm)",
    color = "Sepal Width"
  ) +
  theme_minimal(base_size = 14) +
  theme(
    plot.title = element_text(face = "bold", size = 16),
    panel.grid.major.x = element_blank(),
    legend.position = "right"
  )
