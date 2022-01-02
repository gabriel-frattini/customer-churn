library(ggplot2)
library(caTools)
library(dplyr)
library(hmeasure)
library(MASS)
library(pROC)
library(patchwork)
library(DiscriMiner)
library(party)
library(gridExtra)

df <-read.csv(file.choose(), header=T)

# factoring the variables

df$HasCrCard <- factor(df$HasCrCard)
df$IsActiveMember <- factor(df$IsActiveMember)
df$Geography<-factor(df$Geography)
df$Gender<-factor(df$Gender)
df$Exited <- factor(df$Exited)

# changing the name from exited to churn and removing unnecessary columns

df$Churn<-df$Exited
df<-df[,c(-(1:3),-14)]
prop.table(table(df$Churn))

#continous measures

p1<-ggplot(df, aes(x=Churn, y=Age)) + geom_boxplot(fill=c("#1170aa","#fc7d0b")) 
p2<-ggplot(df, aes(x=Churn, y=Balance)) + geom_boxplot(fill=c("#1170aa","#fc7d0b")) +
  ylab("Balance $")
p3<-ggplot(df, aes(x=Churn, y=EstimatedSalary)) + geom_boxplot(fill=c("#1170aa","#fc7d0b")) +
  ylab("Salary")
p4<-ggplot(df, aes(x=Churn, y=CreditScore)) + geom_boxplot(fill=c("#1170aa","#fc7d0b")) +
  ylab("Credit Score")

grid.arrange(p1,p2,p3,p4, nrow=2, top = ("Continuous Variables"))


#discrete measures

b1<-ggplot(df, aes(x=IsActiveMember, fill=Churn)) + 
  geom_bar(position = "dodge") + 
  scale_fill_manual(values=c("#1170aa","#fc7d0b")) +
  xlab("Member Activity") +
  scale_x_discrete(labels=c("Not Active","Active"))
b2<-ggplot(df, aes(x=Geography, fill=Churn)) + 
  geom_bar(position = "dodge") + 
  scale_fill_manual(values=c("#1170aa","#fc7d0b"))
b3<-ggplot(df, aes(x=Gender, fill=Churn)) + 
  geom_bar(position = "dodge") + 
  scale_fill_manual(values=c("#1170aa","#fc7d0b"))
b4<-ggplot(df, aes(x=HasCrCard, fill=Churn)) + 
  geom_bar(position = "dodge") + 
  scale_fill_manual(values=c("#1170aa","#fc7d0b")) +
  xlab("Has a Credit card") +
  scale_x_discrete(labels=c("No","Yes"))

grid.arrange(b1,b2,b3,b4,nrow=2, top="Discrete Variables")

tree<- ctree(Churn~Geography+Gender, data=df)
plot(tree)


# checking for mulivariate normality
qqnorm(df$Balance,col="#1170aa")
qqline(df$Balance,col="#fc7d0b", lwd=3)

# correlation matrix

num.df<-df[,unlist((lapply(df, is.numeric)))]
cor(num.df)


# churn-rate vs account balance

df$Churn<-as.numeric(df$Churn)

df$Churn[df$Churn==1] <- 0
df$Churn[df$Churn==2] <- 1

tab<-df %>%
  mutate(Deciles = ntile(df$Balance,10)) %>%
  group_by(Geography, Deciles) %>%
  summarise(churn_rate = (sum(Churn)/length(Churn)))


ggplot(tab, aes(x= Deciles, y=churn_rate, color=Geography)) +
  geom_line() +
  geom_point() +
  xlab("Balance $ in deciles")+
  ylab("Churn rate") +
  scale_color_manual(values=c("#1170aa","#fc7d0b","#59A14F"))


# balance in unit scale of 10 000 and dummy variable for german/not german

df$Balance<-df$Balance/10000

df<-df[,-12]

df$Geography<-ifelse(df$Geography=="Germany",1,0)
df$Germany<-df$Geography
df<-df[,-2]


# logistic regression 

log.model<- glm(Churn~CreditScore+Germany+Gender+Age+Balance+NumOfProducts+IsActiveMember, data=df, family = "binomial")
exp(log.model$coefficients)



# the average customer profile

e<-exp(log.model$coefficients[1]+
      (log.model$coefficients[2]*mean(df$CreditScore))+
      (log.model$coefficients[3]*1)+
      (log.model$coefficients[4]*mean(df$Age))+
      (log.model$coefficients[5]*mean(df$Balance))+
      (log.model$coefficients[6]*1))



# Relationship between odds and probability

log.model_age<- glm(Churn~Age, data=df, family = "binomial")

log_odds<-log.model_age$coefficients[1] + (log.model_age$coefficients[2]*df$Age)
odds<-exp(log_odds)
p<-odds/(1+odds)
d <- data.frame(log_odds, odds, p, age = df$Age)
ggplot(d, aes(x = log_odds, y = odds)) +
  geom_line(color="#1170aa") +
  labs(title = "odds versus log-odds") +
  scale_x_continuous(breaks = seq(-3, 25, by = 1)) +
  scale_y_continuous(breaks = seq(0, 5, by = 1))


#split data into train and test data

split<-sample(c(rep(0,.7*nrow(df)), c(rep(1,0.3*nrow(df)))))

train<-df[split==0,]
test<-df[split==1,]

#logistic regression
df$Churn <- factor(df$Churn)
summary(log.model)

#plot for train data classes and then tuning probabilities

log.model<- glm(Churn~CreditScore+Germany+Gender+Age+Balance+NumOfProducts+IsActiveMember, data=train, family = "binomial")

predicted.df <- data.frame(
  probability.of.churn = log.model$fitted.values,
  Churn = train[,10]
)

pred.df<-predicted.df[order(predicted.df$probability.of.churn),]

ggplot(data=pred.df, aes(x=1:nrow(train), y=probability.of.churn)) +
  geom_point(aes(color=Churn), alpha = 1, shape = 4, stroke = 2) +
  ggtitle("Train data Predictions") + 
  xlab("Index") +
  ylab("Predicted Probability of Exit") + 
  ylim(0,1)+
  scale_color_manual(values=c("#1170aa","#fc7d0b"))

# Roc curve
churn.pred<-predict(log.model,test[,-10], type="response")
churn.pred
auc.model<-colAUC(churn.pred, test[,10],plotROC = T)
abline(h=auc.model,col="green")
text(0.78,0.825,paste("AUC:",round(auc.model,3)))


# logstic regression with tuned probabilities
true.class<-test[,10]
churn.pred<-predict(log.model,test[,-10], type="response")
churn.class<-ifelse(churn.pred>0.17,1,0)
log.metric<-misclassCounts(churn.class,true.class)
log.metric$metrics[c("ER","Sens","Spec")]


# LDA

# removing non-normal data
qqnorm(df_norm$Balance)
df_norm<-subset(df,df$Balance>0)
df_num<-select_if(df_norm,is.numeric)
df_num<-df_num[,-7]
df_num<-data.frame(df_num,churn = df_norm$Churn)

#scaling variables

scaled_x<-scale(df_num[,-7])

y<-as.vector(df_num[,7])

#Fishers discriminant function
fdf<-desDA(scaled_x,y)

# The impact our predictors has on discriminating the target variable
fdf$discrivar
fdf
# significance for predictors in terms of differentiating groups
# Relative importance in terms of differentiating groups

dcoef<-as.vector(fdf$discrivar[c(2,3,6)])

coef.df<-data.frame(Variable=c("Credit Score","Age", "# Of Products"),Coefficient = dcoef)

ggplot(coef.df, aes(x=Variable, y=Coefficient, fill=Variable)) +
  geom_col(position = "dodge") +
  coord_flip() +
  scale_fill_manual(values=c("#1170aa","#1170aa","#fc7d0b")) +
  ggtitle("variables discriminatory power ")


# split in to training and test data
lda_data<-data.frame(scaled_x, churn=y)

split.lda<-sample(c(rep(0,.7*nrow(lda_data)), c(rep(1,0.3*nrow(lda_data)))))

train.lda<-lda_data[split==0,]
test.lda<-lda_data[split==1,]

# LDa

lda.model<-lda(churn~.,data=train.lda)
lda.pred<- lda.model %>% predict(test.lda[,-7])

class.lda<-lda.pred$class
true.class<-test.lda[,7]
lda.counts<-misclassCounts(class.lda,true.class)

scores.lda<-lda.pred$posterior[,2]
lda.counts.t19<- misclassCounts(scores.lda>.20,true.class)
lda.counts.t19$conf.matrix
lda.counts.t19$metrics[c('ER', 'Sens','Spec')]