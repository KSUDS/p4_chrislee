library(tidyverse)
library(tidymodels)
library(DALEX)
library(vip)
library(patchwork)


httpgd::hgd()
httpgd::hgd_browse()

dat_ml <- read_rds("dat_ml.rds") %>%
    select(arcstyle_ONE.AND.HALF.STORY, arcstyle_ONE.STORY, numbaths,
        tasp, livearea, basement, condition, stories, quality, before1980) %>%
    filter(livearea < 5500) # 99th percentile is 5429.04

set.seed(76)
dat_split <- initial_split(dat_ml, prop = 1/ 2, strata = before1980)

dat_train <- training(dat_split)
dat_test <- testing(dat_split)

#before is now 0 and after is 1
dat_exp <- mutate(dat_train, before1980 = as.integer(dat_train$before1980) - 1)

head(dat_exp$before1980)
head(dat_train$before1980)

bt_model <- boost_tree() %>%
    set_engine(engine = "xgboost") %>%
    set_mode("classification") %>%
    fit(before1980 ~ ., data = dat_train)

logistic_model <- logistic_reg() %>%
    set_engine(engine = "glm") %>%
    set_mode("classification") %>%
    fit(before1980 ~ ., data = dat_train)

vip(bt_model) +
    labs(title = "BT Model Feature Importance") +
    theme_bw()

ggsave("BTImportance.png", plot = last_plot())

vip(logistic_model)

explainer_bt <- DALEX::explain(
    bt_model,
    select(dat_exp, -before1980), dat_exp$before1980, label = "Boosted Trees")

explainer_logistic <- DALEX::explain(
    logistic_model,
    select(dat_exp, -before1980), dat_exp$before1980, label = "Logistic Regression")

performance_logistic <- model_performance(explainer_logistic)
performance_bt <- model_performance(explainer_bt)

plot(performance_bt, performance_logistic)
plot(performance_bt, performance_logistic, geom = "boxplot")

logistic_parts <- model_parts(explainer_logistic,
    loss_function = loss_root_mean_square)

bt_parts <- model_parts(explainer_bt,
    loss_function = loss_root_mean_square)

plot(bt_parts, max_vars = 10)

ggsave("BTImportance2.png", plot = last_plot())


onehouse_before <- predict_parts(explainer_bt,
    new_observation = select(dat_exp, -before1980) %>%
        dplyr::slice(13800), type = "break_down")

onehouse_after <- predict_parts(explainer_bt,
    new_observation = select(dat_exp, -before1980) %>%
        dplyr::slice(8), type = "break_down")

plots <- plot(onehouse_after) + plot(onehouse_before)

ggsave("probability.png", plot = plots)

dat_train %>% dplyr::slice(c(8, 13800))
