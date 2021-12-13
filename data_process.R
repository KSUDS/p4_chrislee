# install.packages("tidymodels")
# install.packages("visdat")
# install.packages("skimr")
library(tidyverse)
library(tidymodels)
library(visdat)
library(skimr)

httpgd::hgd()
httpgd::hgd_browse()

dat <- read_csv("SalesBook_2013.csv") %>%
    select(NBHD, PARCEL, LIVEAREA, FINBSMNT,
        BASEMENT, YRBUILT, CONDITION, QUALITY,
        TOTUNITS, STORIES, GARTYPE, NOCARS,
        NUMBDRM, NUMBATHS, ARCSTYLE, SPRICE,
        DEDUCT, NETPRICE, TASP, SMONTH,
        SYEAR, QUALIFIED, STATUS) %>%
    rename_all(str_to_lower) %>%
    filter(
        totunits <= 2,
        yrbuilt != 0,
        condition != "None") %>%
    mutate(
        before1980 = ifelse(yrbuilt <1980, "before", "after") %>% 
    factor(levels = c("before", "after")),
    quality = case_when(
        quality == "E-" ~ -0.3, quality == "E" ~ 0,
        quality == "E+" ~ 0.3, quality == "D-" ~ 0.7, 
        quality == "D" ~ 1, quality == "D+" ~ 1.3,
        quality == "C-" ~ 1.7, quality == "C" ~ 2,
        quality == "C+" ~ 2.3, quality == "B-" ~ 2.7,
        quality == "B" ~ 3, quality == "B+" ~ 3.3,
        quality == "A-" ~ 3.7, quality == "A" ~ 4,
        quality == "A+" ~ 4.3, quality == "X-" ~ 4.7,
        quality == "X" ~ 5, quality == "X+" ~ 5.3),
    condition = case_when(
        condition == "Excel" ~ 3,
        condition == "VGood" ~ 2,
        condition == "Good" ~ 1,
        condition == "AVG" ~ 0,
        condition == "Avg" ~ 0,
        condition == "Fair" ~ -1,
        condition == "Poor" ~ -2),
    arcstyle = ifelse(is.na(arcstyle), "missing", arcstyle),
    gartype = ifelse(is.na(gartype), "missing", arcstyle),
    attachedGarage = gartype %>% str_to_lower() %>% str_detect("att") %>% as.numeric(),
    detachedGarage = gartype %>% str_to_lower() %>% str_detect("det") %>% as.numeric(),
    carportGarage = gartype %>% str_to_lower() %>% str_detect("cp") %>% as.numeric(),
    noGarage = gartype %>% str_to_lower() %>% str_detect("none") %>% as.numeric(),
    ) %>%
    arrange(parcel, smonth) %>%
    group_by(parcel) %>%
    slice(1) %>%
    ungroup() %>%
    select(-nbhd, -parcel, -status, -qualified, -gartype, -yrbuilt) %>%
    replace_na(
        c(list(
        basement = 0),
        colMeans(select(., nocars, numbdrm, numbaths),
            na.rm = TRUE)
        )
    )

dat %>% ggplot(aes(before1980, numbdrm)) +
    geom_boxplot() +
    xlab("Before 1980") +
    ylab("Numbe of Bedrooms") +
    ggtitle("Boxplot of Number of Bedrooms by Before 1980") +
    theme_bw()

ggsave("boxplot1.png", plot = last_plot())

dat %>% ggplot(aes(before1980, basement)) +
    geom_boxplot() +
    xlab("Before 1980") +
    ylab("Basement Sq. Footage") +
    ggtitle("Boxplot of Basement (sq. ft.) by Before 1980") +
    theme_bw() +
    scale_y_log10()

ggsave("boxplot2.png", plot = last_plot())

dat %>% ggplot(aes(before1980, nocars)) +
    geom_boxplot() +
    xlab("Before 1980") +
    ylab("Garage Size (in cars)") +
    ggtitle("Boxplot of Garage Size by Before 1980") +
    theme_bw()

ggsave("boxplot3.png", plot = last_plot())

dat %>% ggplot(aes(before1980, numbaths)) +
    geom_boxplot() +
    xlab("Before 1980") +
    ylab("Number of Bathrooms") +
    ggtitle("Boxplot of Number of Baths by Before 1980") +
    theme_bw()

ggsave("boxplot4.png", plot = last_plot())

vis_dat(dat)

dat_ml <- dat %>%
    recipe(before1980 ~ ., data = dat) %>%
    step_dummy(arcstyle) %>%
    prep() %>%
    juice()

glimpse(dat_ml)

vis_dat(dat_ml)

write_rds(dat_ml, "dat_ml.rds")
