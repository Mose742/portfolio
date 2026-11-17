# ---------------------------------------------------------------------------
# Kenyan students: from KCSE grade to university graduation
# Input : data/Kenyan_Students_University_Progression.xlsx (6,000 students)
# Output: k1_flow.png, k2_ridges.png, k3_time.png, k4_groups.png
# ---------------------------------------------------------------------------
suppressPackageStartupMessages({
  library(dplyr); library(tidyr); library(readxl); library(forcats); library(ggplot2)
  library(ggtext); library(ggalluvial); library(ggridges); library(scales); library(ragg)
})

f <- list.files("data", pattern = "xlsx$", full.names = TRUE)[1]
d <- read_excel(f)
names(d) <- c("grade", "perf", "ses", "region", "gender", "school", "admit", "program", "grad", "years", "uni")
grades <- c("A", "A-", "B+", "B", "B-", "C+")
d <- d |> mutate(grade = factor(grade, levels = grades))

# ---- Kenyan-flag palette on a dark ground -----------------------------------
bg <- "#101317"; ink <- "#F1EDE4"; mute <- "#8A919C"; faint <- "#262B33"
green <- "#2FA36B"; red <- "#E0413C"; white <- "#E9E4D8"; dim <- "#3A414C"
ttl <- "Inter Display"; txt <- "Inter"

theme_ke <- function(base = 13) {
  theme_minimal(base_size = base, base_family = txt) +
    theme(
      plot.background = element_rect(fill = bg, colour = NA),
      panel.background = element_rect(fill = bg, colour = NA),
      panel.grid = element_blank(),
      plot.title.position = "plot", plot.caption.position = "plot",
      plot.title = element_textbox_simple(family = ttl, face = "bold", size = base * 2.3, colour = ink,
                                          lineheight = 1, margin = margin(b = 8)),
      plot.subtitle = element_textbox_simple(size = base * 1.02, colour = mute, lineheight = 1.3,
                                             margin = margin(b = 22)),
      plot.caption = element_markdown(size = base * .68, colour = mute, hjust = 0, margin = margin(t = 18)),
      axis.text = element_text(colour = mute, size = base * .82),
      axis.title = element_text(colour = mute, size = base * .8),
      legend.position = "none",
      plot.margin = margin(30, 36, 22, 30)
    )
}
cap <- "**Data:** Kenyan Students University Progression · 6,000 students"
save <- function(p, file, w = 13, h = 8) ggsave(file, p, width = w, height = h, dpi = 300, device = agg_png, bg = bg)
hl <- function(x, col) paste0("<b style='color:", col, "'>", x, "</b>")

# ---------------------------------------------------------------------------
# 1 · Flow: KCSE grade -> admitted? -> graduated?
# ---------------------------------------------------------------------------
fl <- d |>
  mutate(admit = factor(if_else(admit == "yes", "Admitted", "Not admitted"), c("Admitted", "Not admitted")),
         grad  = factor(if_else(grad == "yes", "Graduated", "Did not graduate"), c("Graduated", "Did not graduate")),
         path  = case_when(admit == "Not admitted" & grad == "Graduated" ~ "odd",
                           admit == "Admitted" & grad == "Graduated" ~ "ok",
                           TRUE ~ "out")) |>
  count(grade, admit, grad, path)
n_odd <- sum(fl$n[fl$path == "odd"])

lab_nodes <- tibble(
  x = c(rep(1, 6), 2, 2, 3, 3),
  stratum = c(grades, "Admitted", "Not admitted", "Graduated", "Did not graduate"))

p1 <- ggplot(fl, aes(axis1 = grade, axis2 = admit, axis3 = grad, y = n)) +
  geom_alluvium(aes(fill = path), width = .09, alpha = .78, knot.pos = .42, curve_type = "sigmoid", colour = NA) +
  geom_stratum(width = .09, fill = faint, colour = bg, linewidth = 1.2) +
  geom_text(stat = "stratum", aes(label = after_stat(ifelse(x == 1, paste0(stratum, "  ", comma(count)), NA))),
            family = txt, fontface = "bold", colour = ink, size = 3.6, hjust = 1, nudge_x = -.065, na.rm = TRUE) +
  geom_label(stat = "stratum", aes(label = after_stat(ifelse(x == 2, paste0(stratum, "\n", comma(count)), NA))),
             family = txt, fontface = "bold", colour = ink, fill = bg, label.size = 0, size = 3.6,
             lineheight = .95, label.padding = unit(.35, "lines"), na.rm = TRUE) +
  geom_text(stat = "stratum", aes(label = after_stat(ifelse(x == 3, paste0(stratum, "\n", comma(count)), NA))),
            family = txt, fontface = "bold", colour = ink, size = 3.6, hjust = 0, nudge_x = .065,
            lineheight = .95, na.rm = TRUE) +
  scale_fill_manual(values = c(ok = green, odd = red, out = dim)) +
  scale_x_discrete(limits = c("KCSE grade", "University admission", "Graduation"), expand = c(.1, .1),
                   position = "top") +
  scale_y_continuous(expand = c(0, 0)) +
  labs(
    title = paste0("Nearly one in three graduates was ", hl("never admitted", red)),
    subtitle = paste0(
      "6,000 students from KCSE result to graduation. About 70% are admitted at every grade, from A to C+. ",
      hl(paste0(comma(n_odd), " students"), red), " are recorded as not admitted yet still graduated, alongside ",
      hl("3,184 who took the expected route", green), "."),
    x = NULL, y = NULL, caption = cap) +
  theme_ke() +
  coord_cartesian(clip = "off") +
  theme(plot.margin = margin(30, 110, 22, 30), axis.text.y = element_blank(), axis.text.x.top = element_text(colour = ink, face = "bold", size = 12,
                                                                     margin = margin(b = 6)))
save(p1, "k1_flow.png", w = 13, h = 8.2)

# ---------------------------------------------------------------------------
# 2 · Ridgelines: subject performance by KCSE grade
# ---------------------------------------------------------------------------
meds <- d |> group_by(grade) |> summarise(m = median(perf))
p2 <- ggplot(d, aes(perf, fct_rev(grade))) +
  geom_density_ridges(aes(fill = grade == "A" | grade == "C+"), scale = 1.35, rel_min_height = .003,
                      colour = bg, linewidth = .8, bandwidth = 2.2, alpha = .95) +
  geom_point(data = meds, aes(m, as.numeric(fct_rev(grade)) + .06), shape = 21, size = 3.4,
             fill = bg, colour = ink, stroke = 1.1) +
  geom_text(data = meds, aes(m, as.numeric(fct_rev(grade)) + .36, label = number(m, .1)),
            family = txt, size = 3.2, colour = ink, fontface = "bold") +
  scale_fill_manual(values = c(`TRUE` = green, `FALSE` = dim)) +
  scale_x_continuous(limits = c(45, 105), breaks = seq(50, 100, 10), labels = label_percent(scale = 1)) +
  scale_y_discrete(expand = expansion(add = c(.2, 1.1))) +
  labs(
    title = paste0("An ", hl("A", green), " and a ", hl("C+", green), " look the same on paper"),
    subtitle = "Subject performance by KCSE mean grade. Every grade spans the full range from 50% to 100%, and the medians (rings) sit within about three points of each other.",
    x = "Subject performance", y = NULL, caption = cap) +
  theme_ke() +
  theme(axis.text.y = element_text(colour = ink, face = "bold", size = 15, vjust = 0),
        panel.grid.major.x = element_line(colour = faint, linewidth = .4))
save(p2, "k2_ridges.png", w = 12, h = 8.4)

# ---------------------------------------------------------------------------
# 3 · Time to graduation: every 0.1-year step
# ---------------------------------------------------------------------------
tt <- d |> mutate(years = round(years, 1)) |> count(years) |> mutate(edge = years %in% c(4, 6))
p3 <- ggplot(tt, aes(years, n)) +
  geom_segment(aes(xend = years, y = 0, yend = n, colour = edge), linewidth = 1.6, lineend = "round") +
  geom_point(aes(colour = edge, size = edge)) +
  annotate("text", x = 4.08, y = 1040, label = "1,040 students at\nexactly 4.0 years", hjust = 0,
           vjust = .9, family = txt, size = 4, colour = red, fontface = "bold", lineheight = .95) +
  annotate("text", x = 5.92, y = 1004, label = "1,004 students at\nexactly 6.0 years", hjust = 1,
           vjust = .9, family = txt, size = 4, colour = red, fontface = "bold", lineheight = .95) +
  annotate("text", x = 5, y = 330, label = "everyone in between: 150–250 per step", family = txt,
           size = 3.6, colour = mute) +
  scale_colour_manual(values = c(`TRUE` = red, `FALSE` = white)) +
  scale_size_manual(values = c(`TRUE` = 5, `FALSE` = 2.6)) +
  scale_x_continuous(breaks = seq(4, 6, .5), labels = \(x) paste0(x, " yrs"), expand = c(.03, .03)) +
  scale_y_continuous(limits = c(0, 1120), breaks = seq(0, 1000, 250), labels = comma, expand = c(0, 0)) +
  labs(
    title = paste0("Time to graduate piles up at ", hl("the edges", red)),
    subtitle = "Number of students at each recorded time to graduation, in steps of 0.1 years. A third of all students sit exactly on the 4-year floor or the 6-year ceiling, a sign the values were capped.",
    x = NULL, y = "Students", caption = cap) +
  theme_ke() +
  theme(panel.grid.major.y = element_line(colour = faint, linewidth = .4))
save(p3, "k3_time.png", w = 13, h = 7.6)

# ---------------------------------------------------------------------------
# 4 · Every group, admission vs graduation rate
# ---------------------------------------------------------------------------
vars <- c(ses = "Family income", region = "Region", gender = "Gender", school = "School type",
          program = "Programme", uni = "University")
gr <- lapply(names(vars), \(v) d |> group_by(level = .data[[v]]) |>
               summarise(admit = mean(admit == "yes"), grad = mean(grad == "yes"), n = n()) |>
               mutate(var = vars[[v]])) |>
  bind_rows() |>
  mutate(level = recode(level, high = "High", low = "Low", middle = "Middle", rural = "Rural", urban = "Urban",
                        female = "Female", male = "Male", other = "Other", harambee = "Harambee",
                        private = "Private", public = "Public", humanities = "Humanities",
                        vocational = "Vocational"),
         level = gsub(" University", "", level),
         var = factor(var, levels = vars)) |>
  group_by(var) |> mutate(level = fct_reorder(level, admit)) |> ungroup()

ov <- c(admit = mean(d$admit == "yes"), grad = mean(d$grad == "yes"))
p4 <- ggplot(gr, aes(y = level)) +
  geom_vline(xintercept = ov[["admit"]], colour = green, linetype = "dotted", linewidth = .5) +
  geom_vline(xintercept = ov[["grad"]], colour = white, linetype = "dotted", linewidth = .5) +
  geom_segment(aes(x = admit, xend = grad, yend = level), colour = dim, linewidth = 2.4, lineend = "round") +
  geom_point(aes(x = admit), colour = green, size = 4) +
  geom_point(aes(x = grad), colour = white, size = 4) +
  geom_text(data = filter(gr, level %in% c("Other", "Harambee")),
            aes(x = if_else(level == "Other", admit - .006, grad + .006), label = percent(if_else(level == "Other", admit, grad), .1),
                hjust = if_else(level == "Other", 1, 0)),
            family = txt, size = 3.4, fontface = "bold", colour = ink) +
  facet_grid(var ~ ., scales = "free_y", space = "free_y", switch = "y") +
  scale_x_continuous(limits = c(.6, .84), breaks = seq(.6, .8, .05), labels = label_percent(),
                     position = "top") +
  labs(
    title = "Income, region, gender or school: the rates barely move",
    subtitle = paste0(hl("Admission rate", green), " and ", hl("graduation rate", white),
                      " for every group in the data. Nearly all sit within a few points of the overall rates (dotted lines). ",
                      "The widest gaps: students recorded as ", hl("Other", ink), " gender are admitted least, and ",
                      hl("Harambee", ink), " school students graduate most."),
    x = NULL, y = NULL, caption = cap) +
  theme_ke() +
  theme(strip.placement = "outside",
        strip.text.y.left = element_text(angle = 0, hjust = 1, colour = mute, size = 10, face = "bold",
                                         margin = margin(r = 14)),
        panel.spacing.y = unit(.9, "lines"),
        panel.grid.major.x = element_line(colour = faint, linewidth = .4),
        axis.text.y = element_text(colour = ink, size = 10.5))
save(p4, "k4_groups.png", w = 12, h = 10)
message("Done")
