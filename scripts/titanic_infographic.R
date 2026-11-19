# titanic_infographic.R
#
# An example answer to the BIOS-IN5410 project exercise (documents/project.md).
#
# Written by Claude Opus 5 through GitHub Copilot in Visual Studio Code, and
# reviewed by Erik.
#
# Question: Did "women and children first" apply equally to everyone on board
# the Titanic, or did the ticket you held decide whether you survived?
#
# Dataset: datasets::Titanic (built into R; 2201 people, no data files needed)
#
# Usage:
#   Rscript scripts/titanic_infographic.R [palette] [base_text_size] [output_file]
#
# Arguments (all optional, defaults in brackets):
#   palette         Colour scheme: classic, ocean, or mono [classic]
#   base_text_size  Base font size in points, 8-24 [16]
#   output_file     Path of the .png file to write [titanic_infographic.png]
#
# Examples:
#   Rscript scripts/titanic_infographic.R
#   Rscript scripts/titanic_infographic.R ocean 18 figures/titanic.png

library(tidyverse)

# ---- 1. Settings the user can change from the command line ------------------

palettes <- list(
  classic = list(
    survived = "#1B7F79", ink = "#1D1F21",
    muted = "#8A9199", backdrop = "#E9E5DE", paper = "#FBF8F3"
  ),
  ocean = list(
    survived = "#2A6F97", ink = "#13293D",
    muted = "#7D8FA1", backdrop = "#E3ECF2", paper = "#F7FBFD"
  ),
  mono = list(
    survived = "#2E2E2E", ink = "#111111",
    muted = "#7A7A7A", backdrop = "#E8E8E8", paper = "#FFFFFF"
  )
)

args <- commandArgs(trailingOnly = TRUE)

palette_name <- if (length(args) >= 1) args[1] else "classic"
base_text_size <- if (length(args) >= 2) as.numeric(args[2]) else 16
output_file <- if (length(args) >= 3) args[3] else "titanic_infographic.png"

# Fail early and loudly: a script that is used by other people should explain
# what went wrong rather than produce a broken plot.
if (!palette_name %in% names(palettes)) {
  stop(
    "Unknown palette '", palette_name, "'. Choose one of: ",
    paste(names(palettes), collapse = ", "),
    call. = FALSE
  )
}

if (is.na(base_text_size) || base_text_size < 8 || base_text_size > 24) {
  stop("base_text_size must be a number between 8 and 24.", call. = FALSE)
}

colours <- palettes[[palette_name]]

# ---- 2. Data: from a 4-dimensional table to a tidy data frame ---------------

# datasets::Titanic is a contingency table, so turn it into one row per
# Class / Sex / Age / Survived combination with a count column, n.
titanic <- as_tibble(datasets::Titanic) |>
  mutate(
    Class = factor(Class, levels = c("1st", "2nd", "3rd", "Crew")),
    Survived = factor(Survived, levels = c("No", "Yes"))
  )

# Survival rate per passenger group, which is what the main panel shows.
survival_by_group <- titanic |>
  group_by(Sex, Class) |>
  summarise(
    people = sum(n),
    survivors = sum(n[Survived == "Yes"]),
    .groups = "drop"
  ) |>
  filter(people > 0) |>
  mutate(
    survival_rate = survivors / people,
    Sex = factor(Sex, levels = c("Female", "Male"), labels = c("Women", "Men")),
    # Bars read top-to-bottom from the most expensive ticket to the crew.
    Class = fct_rev(Class),
    label = paste0(round(100 * survival_rate), "%"),
    # Long bars get their percentage printed inside them, short bars outside,
    # so the text never lands on top of anything else.
    label_inside = survival_rate >= 0.25,
    label_hjust = if_else(label_inside, 1.15, -0.15),
    label_colour = if_else(label_inside, colours$paper, colours$ink)
  )

# A few headline numbers for the subtitle, computed rather than typed by hand.
rate_of <- function(...) {
  selected <- filter(titanic, ...)
  sum(selected$n[selected$Survived == "Yes"]) / sum(selected$n)
}

overall_rate <- rate_of(TRUE)
first_class_women <- rate_of(Class == "1st", Sex == "Female")
third_class_women <- rate_of(Class == "3rd", Sex == "Female")
first_class_children <- rate_of(Class %in% c("1st", "2nd"), Age == "Child")
third_class_children <- rate_of(Class == "3rd", Age == "Child")

as_percent <- function(x) paste0(round(100 * x), "%")

# ---- 3. Sizes that follow the chosen text size ------------------------------

title_size <- base_text_size * 1.9
subtitle_size <- base_text_size * 0.85
caption_size <- base_text_size * 0.6

# The canvas grows with the text, but more slowly, so bigger text really does
# look bigger without pushing the headline off the edge of the image.
canvas_scale <- (base_text_size / 16)^0.75
plot_width <- 11 * canvas_scale
plot_height <- 6.5 * canvas_scale

# Roughly how many characters fit on one line at a given font size, used to
# wrap the text blocks instead of letting them run past the margin.
line_length <- function(text_size, character_width = 0.5) {
  max(20, floor(72 * plot_width * 0.9 / (text_size * character_width)))
}

# ---- 4. The infographic -----------------------------------------------------

infographic <- ggplot(survival_by_group, aes(x = survival_rate, y = Class)) +
  # A faint full-width bar gives every group a visible "out of 100%" frame.
  geom_col(aes(x = 1), fill = colours$backdrop, width = 0.65) +
  geom_col(fill = colours$survived, width = 0.65) +
  geom_text(
    aes(label = label, hjust = label_hjust, colour = label_colour),
    size = base_text_size / 2.6,
    fontface = "bold",
    show.legend = FALSE
  ) +
  # Group sizes line up in their own column to the right of every bar.
  geom_text(
    aes(x = 1.04, label = paste(people, "on board")),
    hjust = 0,
    size = base_text_size / 4.5,
    colour = colours$muted
  ) +
  facet_wrap(~Sex) +
  scale_colour_identity() +
  scale_x_continuous(limits = c(0, 1.42), expand = expansion(mult = c(0, 0))) +
  labs(
    title = str_wrap(
      "Women and children first \u2014 if you could afford it",
      width = line_length(title_size, character_width = 0.46)
    ),
    subtitle = str_wrap(
      paste0(
        "Only ", as_percent(overall_rate), " of the 2201 people aboard the ",
        "Titanic survived. Among women, ", as_percent(first_class_women),
        " of first-class passengers lived, against ",
        as_percent(third_class_women), " in third class. Every child in ",
        "first and second class survived (", as_percent(first_class_children),
        "); in third class, ", as_percent(third_class_children), " did."
      ),
      width = line_length(subtitle_size)
    ),
    caption = str_wrap(
      paste0(
        "Share of each group that survived | Source: datasets::Titanic, ",
        "British Board of Trade (1990) | Palette: ", palette_name
      ),
      width = line_length(caption_size)
    ),
    x = NULL,
    y = NULL
  ) +
  theme_minimal(base_size = base_text_size) +
  theme(
    plot.background = element_rect(fill = colours$paper, colour = NA),
    plot.title = element_text(
      face = "bold", size = title_size, colour = colours$ink,
      lineheight = 1.1, margin = margin(b = 10)
    ),
    plot.subtitle = element_text(
      size = subtitle_size, colour = colours$muted, lineheight = 1.3,
      margin = margin(b = 22)
    ),
    plot.caption = element_text(
      size = caption_size, colour = colours$muted, hjust = 0,
      lineheight = 1.3, margin = margin(t = 18)
    ),
    plot.caption.position = "plot",
    plot.title.position = "plot",
    plot.margin = margin(32, 32, 24, 32),
    strip.text = element_text(
      face = "bold", size = base_text_size * 1.1, colour = colours$ink,
      hjust = 0, margin = margin(b = 8)
    ),
    axis.text.y = element_text(
      face = "bold", size = base_text_size * 0.9, colour = colours$ink
    ),
    axis.text.x = element_blank(),
    panel.grid = element_blank(),
    panel.spacing.x = unit(2, "lines")
  )

# ---- 5. Write the file ------------------------------------------------------

output_directory <- dirname(output_file)
if (!dir.exists(output_directory)) {
  dir.create(output_directory, recursive = TRUE)
}

ggsave(
  filename = output_file,
  plot = infographic,
  width = plot_width,
  height = plot_height,
  dpi = 200,
  bg = colours$paper
)

cat("Wrote", output_file, "\n")
