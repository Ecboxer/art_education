library(tidyverse)
library(ggplot2)
df <- read_csv('resources/arts_demo_ela_math.csv')
df %>% head()

#Get column names from the original datasets
q_arts <- df %>% colnames() %>% .[grepl("^Q", .)]
q_ela <- df %>% colnames() %>% .[grepl("ela$", .)]
q_math <- df %>% colnames() %>% .[grepl("math$", .)]
q_demo <- df %>% colnames() %>% setdiff(union(q_arts, union(q_ela, q_math)))

#Get performance metrics of interest, % of passing students
perc_34_ela <- q_ela %>% .[grepl("^perc_34", .)]
perc_34_math <- q_math %>% .[grepl("^perc_34", .)]

#Q3 arts supervisor
q3 <- q_arts %>% .[grepl("^Q3_", .)]
df %>% select(q3) %>% sapply(function(x) sum(is.na(x)))
#No missing values

df %>% select(q3) %>%
  colSums() %>% as_data_frame() %>%
  ggplot(aes(x=q3, y=value)) +
  geom_bar(stat = 'identity')
#Many full-time supervisors with duties other than arts
#Get percent passing for all grades in 2018
perc_34_all_2018 <- union(perc_34_ela, perc_34_math) %>%
  .[grepl("All Grades_2018", .)]
df %>% select(perc_34_all_2018) %>% is.na() %>% colSums()
#Missing data for 370 schools
#Get percent passing for 4th graders in 2018
perc_34_4_2018 <- union(perc_34_ela, perc_34_math) %>% 
  .[grepl("4_2018", .)]
df %>% select(perc_34_4_2018) %>% is.na() %>% colSums()
#Schools will be missing data if they do not teach that grade!
df$Q3 <- with(df, ifelse(Q3_1 == 1, '1',
                ifelse(Q3_2 == 1, '2',
                       ifelse(Q3_3 == 1, '3',
                              ifelse(Q3_4 == 1, '4', '0')))))
df$Q3 <- df$Q3 %>% factor(levels=seq(0,4))
df %>% filter(Q3 == '0') %>% count()
#Two schools did not respond to Q3
df %>% select(perc_34_all_2018, Q3) %>% 
  filter(!is.na(`perc_34_All Grades_2018_ela`)) %>%
  filter(Q3 != 0) %>% 
  ggplot(aes(`perc_34_All Grades_2018_ela`, color=Q3)) +
  geom_density()
df %>% select(perc_34_all_2018, Q3) %>% 
  filter(!is.na(`perc_34_All Grades_2018_ela`)) %>%
  filter(Q3 != 0) %>% 
  ggplot(aes(`perc_34_All Grades_2018_ela`)) +
  geom_histogram() + facet_wrap(vars(Q3))
#Do not see any particular trends
#Look at the scatter plot of ELA and math scores
#Rename columns of interest
temp <- c('perc_34_all_2018_ela', 'perc_34_all_2018_math')
colnames(df)[colnames(df) %in% perc_34_all_2018] <- temp
perc_34_all_2018 <- temp

df %>% select(perc_34_all_2018, Q3) %>%
  filter(!is.na(perc_34_all_2018_ela)) %>% 
  filter(Q3 != 0) %>% 
  ggplot(aes(x=perc_34_all_2018_ela, y=perc_34_all_2018_math)) +
  geom_point() + facet_wrap(vars(Q3))
#All schools have a positive relationship between ELA and math scores
#There is no particular relationship between passing and Q3
#Calculate lm for each Q3 value


#Q4 is the arts supervisor certified in an arts discipline
df %>% filter(Q3_4 == 0) %>% select(Q4_1, Q4_2) %>%
  colSums() %>% as_data_frame() %>% 
  ggplot(aes(x=c('Q4_1', 'Q4_2'), y=value)) +
  geom_bar(stat = 'identity')
#Most supervisors are not certified in an arts discipline
