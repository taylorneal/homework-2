library(tidyverse)
library(rsample)
library(modelr)

###
### Problem 1 ###
###


###
### Problem 2 ###
###


###
### Problem 3 ###
###
credit <- read.csv("https://raw.githubusercontent.com/taylorneal/homework-2/master/data/german_credit.csv", header = TRUE)

# bar plot of default probability by credit rating classification
credit_history = credit %>%
  group_by(history) %>% 
  summarize(default_rate = mean(Default))
credit_history$history = str_to_title(credit_history$history)

ggplot(credit_history, aes(y = default_rate, x = history)) + geom_bar(stat = "identity", fill = "steelblue") + xlab("Credit History") + ylab("Default Rate") + theme_minimal() + ggtitle("Default Probability by Credit History")

# logistic regression model for predicting default probability
credit_split =  initial_split(credit, prop = 0.8)
credit_train = training(credit_split)
credit_test  = testing(credit_split)

logit_default = glm(Default ~ duration + amount + installment + age + history + purpose + foreign, data = credit_train, family = "binomial")

phat_test_credit_default = predict(logit_default, credit_test, type = "response")
dhat_test_credit_default = ifelse(phat_test_credit_default > 0.5, 1, 0)
confusion_out_logit = table(default = credit_test$Default, dhat = dhat_test_credit_default)

# display coefficients and confusion matrix
coef(logit_default) %>% round(2)
confusion_out_logit

###
### Problem 4 ###
###
hotels_dev <- read.csv("https://raw.githubusercontent.com/taylorneal/homework-2/master/data/hotels_dev.csv", header = TRUE)
hotels_val <- read.csv("https://raw.githubusercontent.com/taylorneal/homework-2/master/data/hotels_val.csv", header = TRUE)

# train / test split
hotels_dev_split =  initial_split(hotels_dev, prop = 0.8)
hotels_dev_train = training(hotels_dev_split)
hotels_dev_test  = testing(hotels_dev_split)

# establish baseline models
baseline_1 = lm(children ~ market_segment + adults + customer_type + is_repeated_guest, data = hotels_dev_train)
baseline_2 = lm(children ~ . - arrival_date, data = hotels_dev_train)

# proposed linear model
hotels_dev_train = hotels_dev_train %>% mutate(two_adults = adults == 2)
hotels_dev_test = hotels_dev_test %>% mutate(two_adults = adults == 2)

my_model_start = lm(children ~ . - arrival_date - assigned_room_type, data = hotels_dev_train)

lm_step = step(my_model_start, scope = ~ (.)^2)

# compare to baseline
rmse(baseline_1, hotels_dev_test)
rmse(baseline_2, hotels_dev_test)
rmse(my_model, hotels_dev_test)
