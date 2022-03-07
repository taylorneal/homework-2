library(tidyverse)
library(rsample)
library(modelr)
library(glmnet)
library(lubridate)
library(ROCR)

###
### Problem 1 ###
###
capmetro <- read.csv("https://raw.githubusercontent.com/taylorneal/homework-2/master/data/capmetro_UT.csv", header = TRUE)

capmetro = capmetro %>%
  mutate(day_of_week = factor(day_of_week, levels = c("Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun")), month = factor(month, levels = c("Sep", "Oct", "Nov")))

capmetro_hourly = capmetro %>% 
  group_by(hour_of_day, day_of_week, month) %>%
  summarise(mean_boarding = mean(boarding, na.rm=T), .groups = "drop")

ggplot(capmetro_hourly) + geom_line(aes(x = hour_of_day, y = mean_boarding, color = month)) + facet_wrap(~day_of_week) + labs(x = "Hour of Day", y = "Mean Number of Boardings", color = "Month") + theme_minimal() + ggtitle("Mean Hourly Capital Metro Boardings (to, from, and around UT)")

ggplot(capmetro) + geom_point(aes(x = temperature, y = boarding, color = weekend)) + facet_wrap(~hour_of_day) + labs(x = "Temperature (degrees F)", y = "Boardings", color = "Weekend / Weekday") + theme_minimal() + ggtitle("Boardings vs Temperature, Faceted by Hour of the Day")

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
hotels_dev_train = hotels_dev_train %>% 
  mutate(two_adults = adults == 2,month_arrive = as.factor(month(as.Date(arrival_date))))
hotels_dev_test = hotels_dev_test %>% 
  mutate(two_adults = adults == 2, month_arrive = as.factor(month(as.Date(arrival_date))))


#my_model_start = lm(children ~ . - arrival_date - assigned_room_type - deposit_type - previous_cancellations, data = hotels_dev_train)
#drop1(my_model_start)

hcx = model.matrix(children ~ (. - 1 - assigned_room_type - arrival_date)^2, data = hotels_dev_train)
hcy = hotels_dev_train$children
# remove - deposit_type, previous_cancellations


hclasso = glmnet(hcx, hcy, family = "binomial")
plot(hclasso)
plot(hclasso$lambda, AICc(hclasso))
plot(log(hclasso$lambda), AICc(hclasso))
sum(coef(hclasso)!=0)
#coef(hclasso)[coef(hclasso) != 0,]

#lm_step = step(my_model_start, scope = ~(.)^2)
# add hotel*reserved_room_type + two_adults*reserved_room_type + market_segment*reserved_room_type + reserved_room_type*month_arrive + adults*reserved_room_type + hotel*month_arrive + average_daily_rate*month_arrive

#my_model = lm(children ~ . - arrival_date - assigned_room_type - deposit_type - previous_cancellations + hotel*reserved_room_type + two_adults*reserved_room_type + market_segment*reserved_room_type + reserved_room_type*month_arrive, data = hotels_dev_train)
#drop1(my_model_start)?

pred_base1 <- predict(baseline_1, hotels_dev_test, type="response")
pred_base1 <- prediction(pred_base1, hotels_dev_test$children)
perf_base1 <- performance(pred_base1, "rmse")
rmse_base1 = slot(perf_base1, "y.values")

pred_base2 <- predict(baseline_2, hotels_dev_test, type="response")
pred_base2 <- prediction(pred_base2, hotels_dev_test$children)
perf_base2 <- performance(pred_base2, "rmse")
rmse_base2 = slot(perf_base2, "y.values")

pred_hclasso <- predict(hclasso, hotels_dev_test, type = "response")
pred_hclasso <- prediction(pred_hclasso, hotels_dev_test$children)
perf_hclasso <- performance(pred_hclasso, "rmse")
rmse_hclasso = slot(perf_hclasso, "y.values")
