if (file.exists(here::here("jma-4stations-weather_201804.rds")) == FALSE) {

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

# library(dplyr)
# library(gganimate)

# 
# library(gapminder)  
# ggplot(gapminder, aes(gdpPercap, lifeExp, size = pop, frame = continent)) +
#   geom_point()
# 
# 
# gganimate(p)

