##################################
# Title: 痒い所に手が届くggplot2作図の技
# Author: Shinya Uryu
# knitr::purl("slide.Rmd")
##################################
# データの用意 ------------------------------------------------------------------
if (file.exists(here::here("jma-4stations-weather_201804.rds")) == FALSE) {
  
  # devtools::install_git("https://gitlab.com/uribo/jmastats")
  library(dplyr)
  library(jmastats)
  library(purrr)
  
  df_weather <- 
    stations %>% 
    filter(station_name %in% c("つくば", "水戸",
                               "岡山", "慶良間", "音威子府")) %>%
    distinct(block_no, .keep_all = TRUE) %>% 
    magrittr::use_series(block_no) %>% 
    map_dfr(
      ~ jmastats::jma_collect("daily", block_no = .x, year = 2018, month = 4) %>% 
        mutate(block_no = .x)
    ) %>% 
    select(date, block_no, `降水量_合計(mm)`, starts_with("気温")) %>% 
    purrr::set_names(c("date",
                       "block_no",
                       "precipitation", 
                       "temp_mean", "temp_max", "temp_min")) %>%
    left_join(stations %>% 
                distinct(area, station_name, block_no), 
              by = "block_no") %>% 
    select(date, area, block_no, station_name, everything()) %>% 
    tibble::as_tibble() %>% 
    # 見本のため、あえて文字列にしておく
    mutate(date = as.character(date))
  
  df_weather %>% 
    readr::write_rds(here::here("jma-4stations-weather_201804.rds"))
} else {
  df_weather <- 
    readr::read_rds(here::here("jma-4stations-weather_201804.rds"))
}

## ---- echo = TRUE--------------------------------------------------------
library(tidyverse)

## ------------------------------------------------------------------------
# データの一部を表示
glimpse(df_weather)

## ------------------------------------------------------------------------
df_weather4plot <- 
  df_weather %>% 
  group_by(block_no, station_name) %>% 
  summarise(
    temp_mean = mean(temp_mean, 
                     na.rm = TRUE)) %>% 
  ungroup()

## ------------------------------------------------------------------------
df_weather4plot

## ----plot1_raw, eval = FALSE, echo = TRUE--------------------------------
df_weather4plot %>%
  ggplot(aes(station_name, temp_mean)) +
  geom_bar(stat = "identity")

## ------------------------------------------------------------------------
# station_name変数を因子型に変換
df_weather4plot$station_name

df_weather4plot %>% 
  mutate(station_name = fct_reorder(station_name, temp_mean)) %>% 
  magrittr::use_series(station_name)

## ----plot1, eval = FALSE, echo = TRUE------------------------------------
# 平均気温の平均値が小さい順に
plot1 <-
  df_weather4plot %>%
  ggplot(
    aes(fct_reorder(station_name, temp_mean),
        temp_mean)) +
  geom_bar(stat = "identity")

plot1

## ----update_plot1, eval = FALSE, echo = TRUE-----------------------------
plot1 +
  geom_bar(stat = "identity",
           aes(fill = temp_mean)) +
  geom_text(
    aes(x = station_name,
        y = temp_mean - max(temp_mean) * 0.05,
        label = round(temp_mean, digits = 2)),
    vjust = 1,
    color = "white") +
  coord_flip() +
  xlab(NULL) +
  scale_fill_continuous(type = "viridis") +
  ylab(paste0("4月の平均気温", "(\u2103)")) +
  theme_minimal(base_size = 16) +
  guides(fill = FALSE)

## ----raw_plot2, eval = FALSE, echo = TRUE, message = FALSE---------------
df_weather %>%
  filter(station_name == "岡山") %>%
  ggplot(
    aes(date, temp_mean,
        group = block_no)) +
  geom_point() +
  geom_line()


## ------------------------------------------------------------------------
class(df_weather$date[1])

## ---- message = FALSE----------------------------------------------------
library(lubridate)
class(ymd(df_weather$date[1]))

## ------------------------------------------------------------------------
df_weather <- 
  df_weather %>% 
  mutate(date = ymd(date))

# date列が<date>となっているのを確認
head(df_weather)

## ----plot2, eval = FALSE, echo = TRUE, message = FALSE-------------------
plot2 <-
  df_weather %>%
  filter(station_name == "岡山") %>%
  ggplot(
    aes(date, temp_mean,
        group = block_no)) +
  geom_point() +
  geom_line()

plot2

## ------------------------------------------------------------------------
df_temperature_gather <- df_weather %>% 
  gather("temperature", "value", 
         temp_mean, temp_max, temp_min) %>% 
  mutate(temperature = recode(temperature,
                              temp_mean = "平均",
                              temp_max  = "最高",
                              temp_min  = "最低") %>% 
           fct_reorder(value, .desc = TRUE))

glimpse(df_temperature_gather)

## ----plot2_update, eval = FALSE, echo = TRUE-----------------------------
df_temperature_gather %>%
  ggplot(aes(date, value,
             group = temperature,
             color = temperature)) +
  geom_point() + geom_line() +
  scale_x_date(date_labels = "%b %d",
               date_breaks = "7 day") +
  xlab(NULL) +
  ylab(paste0("気温", "(\u2103)")) +
  guides(color = guide_legend(title = "気温")) +
  facet_wrap(~ station_name, nrow = 5)

## ------------------------------------------------------------------------
df_weather4plot <- 
  df_weather %>% 
  # 入れ子にする変数を選択
  nest(date, precipitation, starts_with("temp_"))

# dataという変数ができる
df_weather4plot

## ------------------------------------------------------------------------
# data変数に観測地点ごとのデータが格納されている
head(df_weather4plot$data[[1]]) # 音威子府

## ------------------------------------------------------------------------
# 作図の結果をplot変数に格納
df_group_out <- 
  df_weather4plot %>% 
  mutate(
    plot = map(# 対象の変数（入れ子にしたデータ）
      data,
      # 無名関数を定義
      ~ ggplot(., aes(date, precipitation)) +
        geom_bar(stat = "identity"))
  )

## ------------------------------------------------------------------------
df_group_out %>% 
  # 新たにplot変数が作成されている
  unnest(data, .preserve = plot) %>% 
  head()

## ---- fig.width = 5, fig.height = 4--------------------------------------
df_group_out$plot[[1]] # 音威子府

## ---- fig.width = 5, fig.height = 4--------------------------------------
df_group_out$plot[[5]] # 慶良間

## ---- eval = FALSE, echo = TRUE------------------------------------------
## # .x = 保存するファイルの名前
## # .y = 出力の対象
## # .f = 要素へ適用する処理
## walk2(.x = paste0("images/april-precipitation-", df_group_out$block_no, ".png"),
##       .y = df_group_out$plot,
##       .f = ggsave,
##       width = 4, height = 3)


## 1. gganimate: アニメーションを作成する ------------------------------------------------------------------------
## install.packages("remotes")
## remotes::install_github("dgrtwo/gganimate")
library(gganimate)
## ------------------------------------------------------------------------
# 日毎の平均気温の推移を描画
plot4 <- 
  df_temperature_gather %>% 
  filter(station_name == "音威子府", 
         temperature == "平均") %>% 
  select(date, temperature, value) %>%
  # frame = アニメーションの対象
  ggplot(
    aes(date, value, 
        color = temperature, 
        frame = date)) +
  geom_point()

## ---- eval = FALSE, echo = TRUE------------------------------------------
gganimate(plot4)

## ---- eval = FALSE, echo = TRUE------------------------------------------
df_temperature_gather %>%
  select(date, station_name,
         temperature, value) %>%
  ggplot(aes(date, value,
             color = temperature,
             frame = date,
             group = station_name,
             cumulative = TRUE)) +
  geom_point(size = 2) +
  geom_line() +
  guides(color = FALSE) +
  xlab(NULL) +
  ylab(paste0("気温", "(\u2103)")) +
  facet_wrap(~ station_name)

## ggrepel: テキスト、ラベルの配置をよしなに ------------------------------------------------------------------------
library(ggrepel)
df_okym <- 
  df_temperature_gather %>% 
  filter(station_name == "岡山")

## ----plot5, eval = FALSE, echo = TRUE------------------------------------
df_okym %>%
  ggplot(aes(date, value,
             label = temperature,
             color = temperature)) +
  geom_point() + geom_line() +
  geom_label_repel(data = df_okym %>%
                     group_by(temperature) %>%
                     arrange(desc(date)) %>%
                              slice(1L),
                           size = 5,
                           nudge_x = 0.25) +
  guides(color = FALSE)

## 3. gghighlight: 要素の一部をハイライト ------------------------------------------
## remotes::install_github("yutannihilation/gghighlight")
library(gghighlight)

## ----plot6, eval = FALSE, echo = TRUE, message = FALSE------------------------------------
df_temperature_gather %>%
  filter(temperature == "平均") %>%
  ggplot() +
  geom_line(aes(date, value,
                group = station_name)) +
  geom_highlight(grepl("(岡山|つくば)",
                       station_name))

## 4. egg: グラフ配置を自在に操る ------------------------------------------------------------------------
library(egg)

df_okym_weekly_precipitation <- 
  df_okym %>% 
  # isoweek()はlubridateの関数
  mutate(isoweek = isoweek(date)) %>% 
  group_by(isoweek) %>% 
  summarise(precipitation = sum(precipitation))

df_okym_weekly_precipitation

## ------------------------------------------------------------------------
plot7_a <- 
  df_okym_weekly_precipitation %>% 
  ggplot(aes(isoweek, precipitation)) +
  geom_bar(stat = "identity")

plot7_b <- 
  df_okym %>% 
  ggplot() +
  geom_line(aes(date, value, 
                color = temperature))

## ----plot7_1col, eval = FALSE, echo = TRUE-------------------------------
ggarrange(plot7_a, plot7_b, nrow = 2)
## ----plot7_2col, eval = FALSE, echo = TRUE-------------------------------
ggarrange(plot7_a, plot7_b, nrow = 1)
