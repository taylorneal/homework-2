library(tidyverse)
library(rsample)

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
credit_split =  initial_split(credit, prop=0.8)
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