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

#Q4 is the arts supervisor certified in an arts discipline
df %>% filter(Q3_4 == 0) %>% select(Q4_1, Q4_2) %>%
  colSums() %>% as_data_frame() %>% 
  ggplot(aes(x=c('Q4_1', 'Q4_2'), y=value)) +
  geom_bar(stat = 'identity')
#Most supervisors are not certified in an arts discipline

#Q5 is the arts supervisor certified as an administrator
df %>% filter(Q3_4 == 0) %>% select(Q5_1, Q5_2) %>% 
  colSums() %>% as_data_frame() %>% 
  ggplot(aes(x=c('Q5_1', 'Q5_2'), y=value)) +
  geom_bar(stat = 'identity')
#Most supervisors are certified in an arts discipline

#Intersection of Q4 and 5
df %>% filter(Q3_4 == 0) %>% select(Q4_1, Q4_2, Q5_1, Q5_2) %>% 
  group_by(Q4_1, Q5_1) %>% count() %>% 
  ggplot(aes(x=c('(0,0)', '(0,1)', '(1,0)', '(1,1)'), y=n)) +
  geom_bar(stat='identity')
#Most supervisors are certified only as administrators
#More are not certified at all than are certified in only an arts discipline or in both

#Q6 part-time certified arts teachers
q6 <- df %>% colnames() %>% .[grepl("^Q6_", .)]
df %>% select(q6) %>% 
  is.na() %>% colSums()
#No missing values
df %>% select(q6) %>% colSums() %>% 
  as_data_frame() %>% 
  ggplot(aes(x=c('Dance', 'Music', 'Theater', 'Visual Arts'), y=value)) +
  geom_bar(stat='identity')
#Part-time certified arts teachers are more frequently certified in visual arts and music
df %>% select(q6, Q0_DBN) %>% 
  gather(key=discipline, value=num, -Q0_DBN) %>% 
  ggplot(aes(x=reorder(Q0_DBN, num), y=num)) +
  geom_point(aes(color=discipline), alpha=.2) +
  coord_flip()
#Incomprehensible

#Q7 part-time teachers with 100% arts schedules
q7 <- df %>% colnames() %>% .[grepl('^Q7_', .)]
#Explicitly name the four arts disciplines for many questions
disc_4 <- c('Dance', 'Music', 'Theater', 'Visual Arts')
df %>% select(q7) %>% colSums(na.rm = T) %>% 
  as_data_frame() %>% 
  ggplot(aes(x=disc_4,
             y=value)) +
  geom_bar(stat='identity')
#Same trend, with more than three times as many music or visual arts teachers teaching 100% of their schedule than dance or theater.
#Look at the relative numbers, ie take into account responses to Q6
df %>% select(q6, q7) %>% 
  mutate(prop_1 = Q7_1 / Q6_1,
         prop_2 = Q7_2 / Q6_2,
         prop_3 = Q7_3 / Q6_3,
         prop_4 = Q7_4 / Q6_4) %>% 
  gather(key = discipline,
         value = proportion,
         -q6, -q7) %>%
  select(discipline, proportion) %>% 
  filter(!is.na(proportion)) %>%
  ggplot(aes(discipline, proportion)) +
  geom_point() +
  geom_jitter()
df %>% select(q6, q7) %>% 
  mutate(prop_1 = Q7_1 / Q6_1,
         prop_2 = Q7_2 / Q6_2,
         prop_3 = Q7_3 / Q6_3,
         prop_4 = Q7_4 / Q6_4) %>% 
  gather(key = discipline,
         value = proportion,
         -q6, -q7) %>%
  select(discipline, proportion) %>% 
  filter(!is.na(proportion)) %>%
  ggplot(aes(x=proportion, color=discipline)) +
  geom_density() + 
  scale_color_manual(labels=disc_4,
                     values=c('red', 'blue', 'green', 'orange'))
#There is probably a better way to visualize proportions
#Music and visual arts have the highest proportion of teachers 100% devoted to arts.
df %>% select(q6, perc_34_4_2018_ela) %>%
  lm(perc_34_4_2018_ela ~ Q6_1 + Q6_2 + Q6_3 + Q6_4, data = .) %>% summary()
#Music and Dance have positive effects on ELA performance, Visual Arts and Theater have negative effects. The music coefficient is the only statistically significant one.
#Is this different for math scores?
df %>% select(q6, perc_34_4_2018_math) %>%
  lm(perc_34_4_2018_math ~ Q6_1 + Q6_2 + Q6_3 + Q6_4, data = .) %>% summary()
#The sign of effects are the same, positive for music and dance but negative for theater and visual arts, but the magnitudes are larger. The music coefficient is less significant and the visual arts coefficient is significant at p-value .05.

#Q8 rooms devoted to arts education
q8 <- df %>% colnames() %>% .[grepl('Q8_', .)]
df %>% select(q8) %>% 
  mutate(rm_dance = Q8_R1_C1 + Q8_R1_C2,
         rm_music = Q8_R2_C1 + Q8_R2_C2,
         rm_thtr = Q8_R3_C1 + Q8_R3_C2,
         rm_media = Q8_R4_C1 + Q8_R4_C2) %>% 
  select(starts_with('rm')) %>% 
  gather(key = discipline,
         value = num) %>%
  ggplot(aes(x=num, color=discipline)) +
  geom_density()
#There is the greatest variation in music rooms
df %>% select(q8, perc_34_4_2018_ela) %>% 
  mutate(rm_dance = Q8_R1_C1 + Q8_R1_C2,
         rm_music = Q8_R2_C1 + Q8_R2_C2,
         rm_thtr = Q8_R3_C1 + Q8_R3_C2,
         rm_media = Q8_R4_C1 + Q8_R4_C2) %>% 
  select(starts_with('rm'), perc_34_4_2018_ela) %>% 
  lm(perc_34_4_2018_ela~., data=.) %>% 
  summary()
#No statistically significant coefficients
df %>% select(q8, perc_34_4_2018_math) %>% 
  mutate(rm_dance = Q8_R1_C1 + Q8_R1_C2,
         rm_music = Q8_R2_C1 + Q8_R2_C2,
         rm_thtr = Q8_R3_C1 + Q8_R3_C2,
         rm_media = Q8_R4_C1 + Q8_R4_C2) %>% 
  select(starts_with('rm'), perc_34_4_2018_math) %>% 
  lm(perc_34_4_2018_math~., data=.) %>% 
  summary()
#None for math either

#Q9 technology tools available to students
q9 <- df %>% colnames() %>% .[grepl('Q9_', .)]
df %>% select(q9) %>% colSums() %>% 
  as_data_frame() %>% 
  ggplot(aes(x=reorder(q9, value), y=value)) +
  geom_bar(stat='identity')
#Smartboard is the most frequent tool
df %>% select(q9, perc_34_4_2018_ela) %>% 
  lm(perc_34_4_2018_ela~., data=.) %>% 
  summary()
#_1 Animation software has a significant effect.
#_2 color printers, _4 digital tablets, _19 film cameras have a lesser but still significant effect.
#Does this effect remain if we control for wealth in some form, since these seem like expensive items?
df %>% select(q9, perc_34_4_2018_math) %>% 
  lm(perc_34_4_2018_math~., data=.) %>% 
  summary()
#_4 digital tablets have a significant effect.
#_1 animation software has a lesser but significant effect.

#Q18 arts instructional hours across grade levels
q18 <- df %>% colnames() %>% .[grepl('Q18_', .)]
#Missing this data

#Q16 arts instructional hours for fourth-grade
