# Why R customers leaving?


![header_project2](https://user-images.githubusercontent.com/96744665/148269540-a351e930-3108-4c51-8bff-f5da8ccfac6b.jpg)

***

## Introduction
In this article I will present an analysis on customer churn and investigate the usecases of two different statistical methods for classifying whether a customer will churn or not. The two methods are Fisher’s disrciminants and logistic regression which comes with different assumptions and limitations.
The business requirements for this project are to identify what factors contribute to churn and to build a model that can classify whether a customer will churn or stay with the bank. The dataset can be found on kaggle.
Since the cost of predicting false positives is much greater than predicting false negatives, the model will be evaluated based on recall.

***

## Project Summary
- Gave recommendations based on insights from a logistic regression and linear discriminants
- Derived customer features that effect churn and associated odds
- Identified churn probabilites for an average customer profile for different demographics
- Built a model that predicts churn with a recall of ~75% and specificity of ~63% that can be used to asses different customer profiles

***

## Exploratory Data Analysis
The data consists of 10 000 observations and has eight different features for every customer. By looking at descriptive statistics from the data we can draw following conclusions:
Germany has a higher churn-rate than any other country and It’s also higher among female customers who are inactive and own’s a creditcard.
Customers who churn are generally older and have higher account balances.
Our variables also have very low correlation and are considered to be independent of each other which is also a requirement before we proceed with our statistical methods.

![churn_disc](https://user-images.githubusercontent.com/96744665/148269644-1a66c3a4-c661-4b08-9072-41e550cc8ff3.png)
![churn_cont](https://user-images.githubusercontent.com/96744665/148269656-39d095eb-caa1-47f4-9c91-316221447c80.png)

***

## Linear Discriminant Analysis
The goal of a LDA is to project our dataset of eight dimensions onto a smaller subspace while maintaining the class-discriminatory information, where the classes are one for churn and zero for no churn. This criteria is fulfilled by finding discriminant functions that maximizes the between-class variability to the within-class variability. Unlike logistic regression this method comes with an assumption of multivariate normal distribution, continuous predictors and is also very sensetive to outliers.
Thus in order to proceed I only included continuous variables, removed outliers which was about 1/3 of the data and standardized the remaining 6400 observations.

![disc_vars](https://user-images.githubusercontent.com/96744665/148269704-f9a83402-8f77-42d9-bb0f-e195a0d6f8d5.png)

The discriminatory power was found significant among a customer’s credit score, age and the number of products he/she has bought. The age was clearly a very important factor for seperating the two classes.
Again, we are only evaluating continous variables and because the original data was heavily skewed for balance accounts, this variability is not considered for the discriminants.

***

## Logistic Regression
Logistic regression relies on maximum likelihood which seeks to find regression coefficients such that the predicted probability of churn for each customer corresponds as closely as possible to the customers observed churn status. In other words a probability close to one for customers who churned and close to zero for those how haven’t.
There is no assumption of multivariate normality thus allowing us to so use all available data with categorical variables. It’s also worth mentioning that the coefficients from a multiple logistic regression yields about the same log odds as with single predictor variables which also supports the argument that the variables are not correlated to each other.


[Gist](https://gist.github.com/Gabriele-Frattini/f7af72770ba4b235b2853a7fb2625dcc#file-logistic-regression)


If we exponentiate the log-odds we can interprate the different coefficents as the odds-ratio of churn, given that all other variables are at a fixed value.
We can see that for every year a customer gets older, the odds of churn increase with 7.5% and for every 10 000 $ increase in a bank account, the odds of churn increase with 2.7%
Even if we hold account balance at a fixed size, the odds of churn for german customers are still 114% higher than in france or spain and that the odds of churn for an active member is 64 % less than for an inactive member.

***

## Taking a look at the average customer

![customer_avg](https://user-images.githubusercontent.com/96744665/148269888-b3d05597-1074-4949-8f45-34f9822ac233.jpeg)

The average customer has a credit score of 650 is 39 years old and has 76000 $ in the account.
From the logistic regression I derived the following information for an average customer:
- For a female customer in germany the probability of churn is .349 while males have a probability of .237.
- Outside of germany the numbers are nearly as prominent with probabilites of .198 for females and .125 for males.

We can visualize this with a decision tree.

![tree_churn](https://user-images.githubusercontent.com/96744665/148269966-bd080813-c825-4152-9f66-8a4f7efd9ba2.png)

The fact that no german customers have less than $ 27 000 in ther account and overall have higher balances is also driving the effect of whether a german customer will churn or stay since a higher balance account has a significant effect on the risk of churn. The effect is displayed below where customers balance’s in germany belong among the 4th decile and over.

![churn_balance](https://user-images.githubusercontent.com/96744665/148269986-4b8f2d76-25e7-467c-93bb-6359bc69804a.png)

***

## Recommendations
The bank needs to review their customer service and find differences in how male and female customers are being treated. My recommendation is to send out questionares to accountholders and to start in Germany where the differences are the most prominent.

Analyze what the requirements are for a customer to labeled as “active” and send out questionares to inactive customers to pin point what issues might be related to inactivity

A review of the market strategies and channels since there might be a communication gap between the bank and older customers. It could also be related to how long a customer has been doing business with the bank as a consequence of lost interest. Data for customer registration would need to be collected in order to analyze further why the odds of churn inrease with 7.5% every year a customer gets older.

A further analysis needs to be performed on other banks in germany to identify market gaps and see why customers with more money in their accounts decide to leave the bank, then take changes accordingly.

***

## Classification model
Since the logistic regression could handle more explanatory varibles, It’s the better suited model for the business case.
Since we are prepared to sacrifice overall accuracy for the recall we can find the optimal cutoff by adjusting the probabilies associated with each class and improve the sensetivity.

![train_pred](https://user-images.githubusercontent.com/96744665/148270069-c7bae040-df50-499b-88b8-b4a7335abdff.png)

I decided to tune the probabilites for churn to .17 and tested the model on the test data, which yielded a sensetivity of 74.7% and specificity of 62.6%.
Meaning that the model will predict correctly 75 out of a 100 customers who churn but it will falsely predict churn on 37 customers out of a 100 who actually stays with the bank.

[Gist](https://gist.github.com/Gabriele-Frattini/2427f8485f1816b8efdb4979d0b48245)

With that said the only cost for false negatives will maybe be some extra time, discounts or perks which is not so bad considering the model predicts churn right 3/4 of the time.
