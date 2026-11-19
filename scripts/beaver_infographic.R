# beaver_infographic.R
#
# An example answer to the BIOS-IN5410 project exercise (documents/project.md).
#
# Written by Claude Opus 5 through GitHub Copilot in Visual Studio Code, and
# reviewed by Erik.
#
# Question: Does a beaver's body temperature actually rise while it is active
# outside the lodge, and do two different beavers tell the same story?
#
# Dataset: datasets::beaver1 and datasets::beaver2, stacked into one table
#   (built into R; 214 ten-minute readings, no data files needed)
#
# Usage:
#   Rscript scripts/beaver_infographic.R [palette] [base_text_size] [output_file]
#
# Arguments (all optional, defaults in brackets):
#   palette         Colour scheme: classic, ocean, or mono [classic]
#   base_text_size  Base font size in points, 8-24 [16]
#   output_file     Path of the .png file to write [beaver_infographic.png]
#
# Examples:
#   Rscript scripts/beaver_infographic.R
#   Rscript scripts/beaver_infographic.R ocean 18 figures/beavers.png

library(tidyverse)

# ---- 1. Settings the user can change from the command line ------------------

palettes <- list(
  classic = list(
    active = "#C2451E", resting = "#2F6F8F", band = "#F3E2D8",
    ink = "#1D1F21", muted = "#8A9199", grid = "#E4DFD6", paper = "#FBF8F3"
  ),
  ocean = list(
    active = "#D98E04", resting = "#2A6F97", band = "#E3ECF2",
    ink = "#13293D", muted = "#7D8FA1", grid = "#DCE6ED", paper = "#F7FBFD"
  ),
  mono = list(
    active = "#111111", resting = "#6E6E6E", band = "#ECECEC",
    ink = "#111111", muted = "#7A7A7A", grid = "#E2E2E2", paper = "#FFFFFF"
  )
)

args <- commandArgs(trailingOnly = TRUE)

palette_name <- if (length(args) >= 1) args[1] else "classic"
base_text_size <- if (length(args) >= 2) as.numeric(args[2]) else 16
output_file <- if (length(args) >= 3) args[3] else "beaver_infographic.png"

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

# ---- 2. Data: two datasets stacked into one tidy table ----------------------

# beaver1 and beaver2 have the same four columns, so they can be stacked with
# a column that remembers which animal each reading came from.
readings <- bind_rows(
  "Beaver 1" = as_tibble(datasets::beaver1),
  "Beaver 2" = as_tibble(datasets::beaver2),
  .id = "beaver"
) |>
  mutate(
    # time is a clock reading like 930 or 1410, so split it into hours.
    clock_hour = time %/% 100 + (time %% 100) / 60,
    state = if_else(activ == 1, "Outside the lodge", "In the lodge")
  ) |>
  group_by(beaver) |>
  # Readings run past midnight, so keep counting hours into the second day.
  mutate(hour = clock_hour + 24 * (day - min(day))) |>
  ungroup() |>
  mutate(point_colour = if_else(activ == 1, colours$active, colours$resting))

# Mean temperature per animal and state, which is what the panel labels show.
state_means <- readings |>
  group_by(beaver, state) |>
  summarise(mean_temp = mean(temp), n_readings = n(), .groups = "drop")

# The shaded bands: each unbroken stretch of activity, found by numbering the
# stretches and then taking the first and last reading of each.
activity_bands <- readings |>
  arrange(beaver, hour) |>
  group_by(beaver) |>
  mutate(stretch = cumsum(activ != lag(activ, default = first(activ)))) |>
  filter(activ == 1) |>
  group_by(beaver, stretch) |>
  # Readings are ten minutes apart, so stretch each band half a step outwards.
  summarise(start = min(hour) - 1 / 12, end = max(hour) + 1 / 12, .groups = "drop")

# A few headline numbers, computed rather than typed by hand.
mean_of <- function(active) {
  mean(readings$temp[readings$activ == active])
}

resting_temp <- mean_of(0)
active_temp <- mean_of(1)
temperature_rise <- active_temp - resting_temp
total_readings <- nrow(readings)

as_celsius <- function(x) paste0(format(round(x, 1), nsmall = 1), " \u00B0C")

# ---- 3. Labels drawn directly on each panel ---------------------------------

# The labels sit in the empty strip above the data, one line below the other,
# and take their colour from the points they describe. No legend needed.
panel_labels <- state_means |>
  mutate(
    label_line = if_else(state == "In the lodge", 1.2, 2.5),
    colour = if_else(state == "In the lodge", colours$resting, colours$active),
    label = paste0(
      state, ": ", as_celsius(mean_temp), " (", n_readings, " readings)"
    )
  )

# ---- 4. Sizes that follow the chosen text size ------------------------------

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

# ---- 5. The infographic -----------------------------------------------------

hour_breaks <- seq(6, 48, by = 6)

infographic <- ggplot(readings, aes(x = hour, y = temp)) +
  # Shading marks the stretches the beaver spent outside the lodge.
  geom_rect(
    data = activity_bands,
    aes(xmin = start, xmax = end, ymin = -Inf, ymax = Inf),
    inherit.aes = FALSE,
    fill = colours$band
  ) +
  geom_line(colour = colours$muted, linewidth = 0.4) +
  geom_point(aes(colour = point_colour), size = base_text_size / 9) +
  geom_text(
    data = panel_labels,
    aes(x = -Inf, y = Inf, label = label, colour = colour, vjust = label_line),
    hjust = -0.04,
    size = base_text_size / 4.5,
    fontface = "bold"
  ) +
  facet_wrap(~beaver, ncol = 1) +
  scale_colour_identity() +
  scale_x_continuous(
    breaks = hour_breaks,
    labels = sprintf("%02d:00", hour_breaks %% 24),
    expand = expansion(mult = c(0.01, 0.01))
  ) +
  scale_y_continuous(
    labels = as_celsius,
    expand = expansion(mult = c(0.08, 0.32))
  ) +
  labs(
    title = str_wrap(
      "Beavers heat up the moment they leave the lodge",
      width = line_length(title_size, character_width = 0.46)
    ),
    subtitle = str_wrap(
      paste0(
        "Across ", total_readings, " ten-minute readings from two beavers, ",
        "body temperature averaged ", as_celsius(resting_temp),
        " inside the lodge and ", as_celsius(active_temp),
        " while active outside, a rise of ",
        format(round(temperature_rise, 1), nsmall = 1),
        " \u00B0C. Shaded stretches are time spent outside."
      ),
      width = line_length(subtitle_size)
    ),
    caption = str_wrap(
      paste0(
        "Body temperature of two beavers, measured every ten minutes | ",
        "Source: datasets::beaver1 and datasets::beaver2, Reynolds (1994) | ",
        "Palette: ", palette_name
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
    axis.text = element_text(size = base_text_size * 0.8, colour = colours$muted),
    panel.grid.minor = element_blank(),
    panel.grid.major.x = element_blank(),
    panel.grid.major.y = element_line(colour = colours$grid, linewidth = 0.4),
    panel.spacing.y = unit(1.6, "lines")
  )

# ---- 6. Write the file ------------------------------------------------------

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
