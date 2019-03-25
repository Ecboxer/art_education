library(MatchIt)

summary(lm(re78~treat, data=lalonde))
t.test(lalonde$re78[lalonde$treat==1], lalonde$re78[lalonde$treat==0], paired=FALSE)

m.out1 <- matchit(treat~age+educ+black+hispan+nodegree+married+re74+re75, data=lalonde, method='nearest', distance='logit')
summary(m.out1)
plot(m.out1)

m.data1 <- match.data(m.out1, distance='pscore')
hist(m.data1$pscore, breaks=20)
summary(m.data1$pscore)

t.test(m.data1$re78[m.data1$treat==1], m.data1$re78[m.data1$treat==0], paired=TRUE)

m.data2 <- lalonde
dim(m.data2)
ps.model <- glm(treat~age+educ+black+hispan+nodegree+married+re74+re75, data=m.data2, family=binomial(link='logit'), na.action=na.pass)
summary(ps.model)

m.data2$pscore <- predict(ps.model, newdata=m.data2, type='response')
#type='response' gives us probabilities instead of log-odds

hist(m.data2$pscore, breaks=20)
summary(m.data2$pscore)
dim(m.data2)

#restrict data to ps range .1<=ps<=.9
m.data3 <- m.data2[m.data2$pscore >= .1 & m.data2$pscore <= .9,]
summary(m.data3$pscore)

#regression with controls on propensity score screened dataset
summary(lm(re78~treat+age+educ+black+hispan+nodegree+married+re74+re75, data=m.data3))

#unrestricted regression with controls
summary(lm(re78~treat+age+educ+black+hispan+nodegree+married+re74+re75, data=lalonde))
