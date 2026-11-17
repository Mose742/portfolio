# ---------------------------------------------------------------------------
# School funding, performance and access across public, private and charter
# schools: four charts in ggplot2.
# Input : data/education_inequality_data.csv (1,000 schools, 10 states)
# Output: 01_scores_by_type.png ... 04_states.png
# ---------------------------------------------------------------------------

suppressPackageStartupMessages({
  library(dplyr); library(tidyr); library(readr); library(forcats)
  library(ggplot2); library(ggtext); library(ggbeeswarm); library(patchwork)
  library(scales); library(ragg)
})

d <- read_csv("data/education_inequality_data.csv", show_col_types = FALSE) |>
  mutate(school_type = factor(school_type, levels = c("Public", "Private", "Charter")))

# ---- Look & feel ----------------------------------------------------------
pal <- c(Public = "#2F5D8C", Private = "#D1603D", Charter = "#3B8C6E")
bg  <- "#FBF8F3"; ink <- "#1F2430"; mute <- "#7A7F8C"; grid <- "#E8E2D8"
font <- "Inter"

col_txt <- function(x, col = pal[x]) glue::glue("<b style='color:{col}'>{x}</b>")

theme_edu <- function(base = 13) {
  theme_minimal(base_size = base, base_family = font) +
    theme(
      plot.background  = element_rect(fill = bg, colour = NA),
      panel.background = element_rect(fill = bg, colour = NA),
      panel.grid.minor = element_blank(),
      panel.grid.major = element_line(colour = grid, linewidth = .35),
      plot.title.position = "plot", plot.caption.position = "plot",
      plot.title    = element_textbox_simple(size = base * 1.75, face = "bold", colour = ink,
                                             lineheight = 1.05, margin = margin(b = 14)),
      plot.subtitle = element_textbox_simple(size = base * .98, colour = mute, lineheight = 1.3,
                                             margin = margin(b = 18)),
      plot.caption  = element_textbox_simple(size = base * .7, colour = mute, lineheight = 1.25,
                                             margin = margin(t = 16)),
      axis.title  = element_text(colour = mute, size = base * .8),
      axis.text   = element_text(colour = mute, size = base * .8),
      strip.text  = element_markdown(size = base * 1.05, hjust = 0, margin = margin(b = 6)),
      legend.position = "none",
      plot.margin = margin(28, 32, 20, 28)
    )
}
src <- "**Data:** education_inequality_data.csv · 1,000 schools in 10 US states"
save <- function(p, file, w = 11, h = 7.5) ggsave(file, p, width = w, height = h, dpi = 300, device = agg_png, bg = bg)

# ---------------------------------------------------------------------------
# 1 · Test scores by school type: every school, plus the median
# ---------------------------------------------------------------------------
kw  <- kruskal.test(avg_test_score_percent ~ school_type, d)
med <- d |> group_by(school_type) |>
  summarise(m = median(avg_test_score_percent), q1 = quantile(avg_test_score_percent, .25),
            q3 = quantile(avg_test_score_percent, .75), n = n())

p1 <- ggplot(d, aes(avg_test_score_percent, fct_rev(school_type), colour = school_type)) +
  geom_quasirandom(orientation = "y", width = .32, size = 1.6, alpha = .45, stroke = 0) +
  geom_linerange(data = med, aes(x = NULL, xmin = q1, xmax = q3, y = fct_rev(school_type)),
                 linewidth = 3.2, colour = ink, alpha = .85, inherit.aes = FALSE) +
  geom_point(data = med, aes(x = m), size = 5.2, shape = 21, fill = bg, colour = ink, stroke = 1.4) +
  geom_text(data = med, aes(x = m, label = paste0("median ", number(m, .1), "%")),
            nudge_y = .46, family = font, fontface = "bold", size = 4, colour = ink) +
  scale_colour_manual(values = pal) +
  scale_x_continuous(limits = c(38, 102), breaks = seq(40, 100, 10), labels = label_percent(scale = 1),
                     expand = c(0, 0)) +
  scale_y_discrete(labels = \(x) col_txt(x)) +
  labs(
    title = "Whatever the school type, the typical test score is about 70%",
    subtitle = glue::glue(
      "Each dot is one school. The black bar spans the middle half of schools and the ring marks the median. ",
      "{col_txt('Public')} and {col_txt('Private')} medians sit within one point of each other, and ",
      "{col_txt('Charter')} schools only 4 points lower — a gap smaller than the spread inside any one group ",
      "(Kruskal–Wallis p = {number(kw$p.value, .01)})."),
    x = "Average test score", y = NULL, caption = src) +
  theme_edu() +
  theme(axis.text.y = element_markdown(size = 15), panel.grid.major.y = element_blank())
save(p1, "01_scores_by_type.png", h = 7)

# ---------------------------------------------------------------------------
# 2 · Funding per student vs test score, one panel per school type
# ---------------------------------------------------------------------------
rs <- d |> group_by(school_type) |>
  summarise(r = cor(funding_per_student_usd, avg_test_score_percent),
            slope = coef(lm(avg_test_score_percent ~ I(funding_per_student_usd / 10000)))[2])

strip_lab <- setNames(
  glue::glue("{col_txt(as.character(rs$school_type))}<span style='color:{mute}'>  ·  r = {sub('^[+-]0.00$', '0.00', sprintf('%+.2f', rs$r))}</span>"),
  rs$school_type)

p2 <- ggplot(d, aes(funding_per_student_usd, avg_test_score_percent, colour = school_type)) +
  geom_hline(yintercept = mean(d$avg_test_score_percent), colour = mute, linetype = "dotted") +
  geom_point(size = 1.7, alpha = .4, stroke = 0) +
  geom_smooth(method = "lm", formula = y ~ x, se = TRUE, linewidth = 1.3, fill = "grey70", alpha = .35) +
  geom_text(data = rs, aes(x = 24800, y = 104,
                           label = paste0(sprintf("%+.1f", slope), " pts per extra $10k")),
            hjust = 1, family = font, size = 3.6, colour = ink, inherit.aes = FALSE) +
  facet_wrap(~school_type, labeller = as_labeller(strip_lab)) +
  scale_colour_manual(values = pal) +
  scale_x_continuous(labels = label_dollar(scale = 1e-3, suffix = "k"), breaks = seq(5000, 25000, 5000)) +
  scale_y_continuous(labels = label_percent(scale = 1), limits = c(38, 106), breaks = seq(40, 100, 20)) +
  labs(
    title = "Spending five times more per student barely moves test scores",
    subtitle = glue::glue(
      "Funding runs from about $5,000 to $25,000 per student. For {col_txt('Public')} and {col_txt('Charter')} schools ",
      "the trend is flat. {col_txt('Private')} schools tilt slightly upward (about 3 points per extra $10,000, p = 0.04), ",
      "but funding still explains only about 1% of the variation in their scores. The dotted line is the overall average (70%)."),
    x = "Funding per student", y = "Average test score", caption = src) +
  theme_edu() +
  theme(panel.spacing.x = unit(2.2, "lines"))
save(p2, "02_funding_vs_scores.png", w = 12, h = 6.8)

# ---------------------------------------------------------------------------
# 3 · Poverty x funding grid: average score in each cell
# ---------------------------------------------------------------------------
qlab_f <- c("Lowest\nfunding", "", "", "Highest\nfunding")
grid3 <- d |>
  mutate(fq = ntile(funding_per_student_usd, 4), lq = ntile(percent_low_income, 4)) |>
  group_by(fq, lq) |>
  summarise(score = mean(avg_test_score_percent), n = n(), .groups = "drop") |>
  mutate(dev = score - mean(d$avg_test_score_percent))

fr <- d |> mutate(fq = ntile(funding_per_student_usd, 4)) |> group_by(fq) |>
  summarise(lo = min(funding_per_student_usd), hi = max(funding_per_student_usd)) |>
  mutate(lab = paste0(dollar(lo, scale = 1e-3, suffix = "k", accuracy = 1), "–",
                      dollar(hi, scale = 1e-3, suffix = "k", accuracy = 1)))
lr <- d |> mutate(lq = ntile(percent_low_income, 4)) |> group_by(lq) |>
  summarise(lo = min(percent_low_income), hi = max(percent_low_income)) |>
  mutate(lab = paste0(round(lo), "–", round(hi), "%"))

p3 <- ggplot(grid3, aes(lq, fq, fill = dev)) +
  geom_tile(colour = bg, linewidth = 3, width = .96, height = .92) +
  geom_text(aes(label = number(score, .1)), family = font, fontface = "bold", size = 7.5, colour = ink,
            nudge_y = .08) +
  geom_text(aes(label = paste0(n, " schools")), family = font, size = 3.3, colour = mute, nudge_y = -.22) +
  scale_fill_gradient2(low = "#C0573A", mid = "#F4EEE4", high = "#2F7A8C", midpoint = 0,
                       limits = c(-15, 15), guide = "none") +
  scale_x_continuous(breaks = 1:4, labels = paste0(c("Least poor\n", "", "", "Most poor\n"), lr$lab),
                     expand = c(0, 0), position = "top") +
  scale_y_continuous(breaks = 1:4, labels = paste0(qlab_f, ifelse(qlab_f == "", "", "\n"), fr$lab),
                     expand = c(0, 0)) +
  coord_fixed(ratio = .62) +
  labs(
    title = "Rich or poor, well funded or not, scores barely move",
    subtitle = paste0(
      "Schools split into quarters by share of low-income students (across) and funding per student (up). ",
      "Each tile is the average test score. Every cell lands between 67% and 73%. The colour scale runs ",
      "±15 points around the overall average, so the pale tiles show how small the differences are."),
    x = "Share of students from low-income families", y = "Funding per student", caption = src) +
  theme_edu() +
  theme(panel.grid = element_blank(), axis.ticks = element_blank(), axis.text = element_text(size = 11, colour = ink, lineheight = 1.1),
        axis.title.x.top = element_text(margin = margin(b = 8)))
save(p3, "03_poverty_funding_grid.png", w = 10, h = 8.4)

# ---------------------------------------------------------------------------
# 4 · States: average funding and average score with 95% intervals
# ---------------------------------------------------------------------------
ci <- function(x) { m <- mean(x); se <- sd(x) / sqrt(length(x)); tibble(m = m, lo = m - 1.96 * se, hi = m + 1.96 * se) }
st <- d |> group_by(state) |>
  reframe(var = c("fund", "score"),
          bind_rows(ci(funding_per_student_usd), ci(avg_test_score_percent)), n = n()) |>
  group_by(var) |> mutate(top = m == max(m), bot = m == min(m)) |> ungroup()
ord <- st |> filter(var == "score") |> arrange(m) |> pull(state)
st <- st |> mutate(state = factor(state, levels = ord))
nat <- c(fund = mean(d$funding_per_student_usd), score = mean(d$avg_test_score_percent))

panel <- function(v, xlab, fmt, hl) {
  dd <- st |> filter(var == v)
  ggplot(dd, aes(m, state)) +
    geom_vline(xintercept = nat[[v]], colour = mute, linetype = "dotted") +
    geom_linerange(aes(xmin = lo, xmax = hi), linewidth = 2.6, colour = "#D9D1C4", lineend = "round") +
    geom_point(aes(fill = top | bot), shape = 21, size = 4.2, colour = ink, stroke = .8) +
    geom_text(data = filter(dd, top | bot), aes(label = fmt(m)), nudge_y = .42,
              family = font, size = 3.6, fontface = "bold", colour = ink) +
    scale_fill_manual(values = c(`TRUE` = hl, `FALSE` = bg)) +
    scale_x_continuous(labels = fmt) +
    labs(x = xlab, y = NULL) +
    theme_edu() + theme(panel.grid.major.y = element_blank(), axis.text.y = element_text(colour = ink, size = 12))
}
p4a <- panel("fund", "Average funding per student", label_dollar(scale = 1e-3, suffix = "k", accuracy = .1), "#C9A227")
p4b <- panel("score", "Average test score", label_percent(scale = 1, accuracy = .1), "#2F7A8C") +
  theme(axis.text.y = element_blank())

p4 <- (p4a | p4b) + plot_annotation(
  title = "California tops the test-score table and Ohio sits last, but the gaps are small and uncertain",
  subtitle = paste0(
    "State averages with 95% confidence intervals (grey bars), ordered by test score. Dotted lines mark the ",
    "average across all 1,000 schools. California leads Ohio by 8 points, but most states' intervals overlap. ",
    "Funding ranks don't line up with score ranks: Texas is the second-lowest spender yet ranks 4th on scores, while ",
    "Georgia spends almost as much as top spender New York and ranks 5th."),
  caption = paste0(src, " · Intervals: mean ± 1.96 standard errors"),
  theme = theme_edu())
save(p4, "04_states.png", w = 12, h = 7.6)

message("Done")
