library(tidyverse)
library(ggplot2)
df <- read_csv('resources/arts_demo_ela_math.csv')
df %>% head()

#Q1 do people use non-DOE email

#Get column names from the original datasets
q_arts <- df %>% colnames() %>% .[grepl("^Q", .)]
q_ela <- df %>% colnames() %>% .[grepl("ela$", .)]
q_math <- df %>% colnames() %>% .[grepl("math$", .)]
q_demo <- df %>% colnames() %>% setdiff(union(q_arts, union(q_ela, q_math)))

#Get performance metrics of interest, % of passing students
perc_34_ela <- q_ela %>% .[grepl("^perc_34", .)]
perc_34_math <- q_math %>% .[grepl("^perc_34", .)]

#Get percent passing for all grades in 2018.
perc_34_all_2018 <- union(perc_34_ela, perc_34_math) %>%
  .[grepl("All Grades_2018", .)]
df %>% select(perc_34_all_2018) %>% is.na() %>% colSums()
#Missing data for 370 schools
#Get percent passing for 4th graders in 2018
perc_34_4_2018 <- union(perc_34_ela, perc_34_math) %>% 
  .[grepl("4_2018", .)]
df %>% select(perc_34_4_2018) %>% is.na() %>% colSums()

#Q3 arts supervisor
q3 <- q_arts %>% .[grepl("^Q3_", .)]
df %>% select(q3) %>% sapply(function(x) sum(is.na(x)))
#No missing values
superv_status <- factor(c('FT, solely arts', 'FT, other', 'PT', 'None'),
                          levels=c('FT, solely arts', 'FT, other', 'PT', 'None'))
df %>% select(q3) %>%
  colSums() %>% as_data_frame() %>%
  ggplot(aes(x=superv_status, y=value)) +
  geom_bar(stat = 'identity')
#Many full-time supervisors with duties other than arts.
#There are very few part-time supervisors.

#Schools will be missing data if they do not teach that grade!
df$Q3 <- with(df, ifelse(Q3_1 == 1, '1',
                ifelse(Q3_2 == 1, '2',
                       ifelse(Q3_3 == 1, '3',
                              ifelse(Q3_4 == 1, '4', '0')))))
df$Q3 <- df$Q3 %>% factor(levels=seq(0,4))
df %>% filter(Q3 == '0') %>% count()
#Two schools did not respond to Q3

#Rename columns of interest.
temp <- c('perc_34_all_2018_ela', 'perc_34_all_2018_math')
colnames(df)[colnames(df) %in% perc_34_all_2018] <- temp
perc_34_all_2018 <- temp

df %>% select(perc_34_all_2018, Q3) %>% 
  filter(!is.na(perc_34_all_2018_ela)) %>%
  filter(Q3 != 0) %>% 
  ggplot(aes(perc_34_all_2018_ela, color=Q3)) +
  geom_density()
df %>% select(perc_34_all_2018, Q3) %>% 
  filter(!is.na(perc_34_all_2018_ela)) %>%
  filter(Q3 != 0) %>% 
  ggplot(aes(perc_34_all_2018_ela)) +
  geom_histogram() + facet_wrap(vars(Q3))
#Do not see any particular trends.
#Look at the scatter plot of ELA and math scores.

df %>% select(perc_34_all_2018, Q3) %>%
  filter(!is.na(perc_34_all_2018_ela)) %>% 
  filter(Q3 != 0) %>% 
  ggplot(aes(x=perc_34_all_2018_ela, y=perc_34_all_2018_math)) +
  geom_point() + facet_wrap(vars(Q3))
#All schools have a positive relationship between ELA and math scores.
#There is no particular relationship between passing and Q3.

#Does poverty have any relation with supervisor status?
df %>% select(q3, perc_pov_2017) %>% 
  lm(perc_pov_2017~., data=.) %>% 
  summary()
#No statistically significant coefficients.

#Q4 is the arts supervisor certified in an arts discipline?
df %>% filter(Q3_4 == 0) %>% select(Q4_1, Q4_2) %>%
  colSums() %>% as_data_frame() %>% 
  ggplot(aes(x=c('Q4_1', 'Q4_2'), y=value)) +
  geom_bar(stat = 'identity')
#Most supervisors are not certified in an arts discipline
(q_demo_2017 <- q_demo %>% .[grepl('2017', .)])
#Remove year and school
q_demo_2017 <- q_demo_2017[c(-1, -2)]
df$eni_2017 <- df$eni_2017 %>%
  sub('%', '', x=.) %>%
  as.numeric()
#Is this related with some demographic data?
q4_demo_results <- list()
for (i in q_demo_2017) {
  temp.glm <- df %>% select(Q4_1, i) %>% 
    glm(Q4_1~., data=., family='binomial') %>% 
    summary()
  if (temp.glm$coefficients[2,4] < 0.05) {
    q4_demo_results[i] <- temp.glm$coefficients[2,4]
  }
}
q4_demo_results
#Statistically significant relations with: grd_k to grd_5 and grd_9 to grd_12 and perc_male and perc_female.
#So certification in the arts is related to number of students.
#Which relation with gender is positive?
df %>%
  glm(Q4_1~perc_male_2017, data=., family='binomial') %>% 
  summary()
#There is a negative relation with percentage of male students and having an arts supervisor certified in the arts.

#Q5 is the arts supervisor certified as an administrator
df %>% filter(Q3_4 == 0) %>% select(Q5_1, Q5_2) %>% 
  colSums() %>% as_data_frame() %>% 
  ggplot(aes(x=c('Q5_1', 'Q5_2'), y=value)) +
  geom_bar(stat = 'identity')
#Most supervisors are certified in administration.

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
q16 <- df %>% colnames() %>% .[grepl('Q16_', .)]
df %>% select(q16) %>%
  mutate(
    dance_hr = Q16_C1_R1 + Q16_C2_R1 + Q16_C3_R1 + Q16_C4_R1 + Q16_C5_R1 + Q16_C6_R1 + Q16_C7_R1 + Q16_C8_R1 + Q16_C9_R1 + Q16_C10_R1 + Q16_C11_R1 + Q16_C12_R1 + Q16_C13_R1 + Q16_C14_R1,
    music_hr = Q16_C1_R2 + Q16_C2_R2 + Q16_C3_R2 + Q16_C4_R2 + Q16_C5_R2 + Q16_C6_R2 + Q16_C7_R2 + Q16_C8_R2 + Q16_C9_R2 + Q16_C10_R2 + Q16_C11_R2 + Q16_C12_R2 + Q16_C13_R2 + Q16_C14_R2,
    thtr_hr = Q16_C1_R3 + Q16_C2_R3 + Q16_C3_R1 + Q16_C4_R1 + Q16_C5_R3 + Q16_C6_R3 + Q16_C7_R3 + Q16_C8_R3 + Q16_C9_R3 + Q16_C10_R3 + Q16_C11_R3 + Q16_C12_R3 + Q16_C13_R3 + Q16_C14_R1,
    visart_hr = Q16_C1_R4 + Q16_C2_R4 + Q16_C3_R4 + Q16_C4_R4 + Q16_C5_R4 + Q16_C6_R4 + Q16_C7_R4 + Q16_C8_R4 + Q16_C9_R4 + Q16_C10_R4 + Q16_C11_R4 + Q16_C12_R4 + Q16_C13_R4 + Q16_C14_R4
  ) %>% select(ends_with('_hr'))
#Still end up with NAs

#Extract boroughs
df$boro <- df$Q0_DBN %>% str_extract('\\D')
df$boro %>% unique()
df <- df %>% mutate(
  K = if_else(boro == 'K', 1, 0),
  X = if_else(boro == 'X', 1, 0),
  M = if_else(boro == 'M', 1, 0),
  Q = if_else(boro == 'Q', 1, 0),
  R = if_else(boro == 'R', 1, 0)
  )
df %>% select(perc_34_4_2018_ela, K, X, M, Q, R) %>% 
  lm(perc_34_4_2018_ela~., data=.) %>% 
  summary()
#Bronx has a strong negative relation and Brooklyn a lesser negative relation. All other boroughs are not statistically significant.
df %>% select(perc_34_4_2018_math, K, X, M, Q, R) %>% 
  lm(perc_34_4_2018_math~., data=.) %>% 
  summary()
#Bronx has a strong negative correlation and no other borough has a statistically significant relation.

#Look at relationship between demographics and arts resources.
#Q10 arts disciplines offered, but only for special education schools
q10 <- df %>% colnames() %>% .[grepl('Q10_', .)] %>% .[grepl('_C1', .)]
disc_5 <- c('Dance', 'Film', 'Music', 'Theater', 'Visual Arts')
df %>% select(q10) %>% colSums()

#Q2 do not have a designated arts education liaison
df %>% select(Q2_1) %>% sum()
boros <- c('K', 'X', 'M', 'Q', 'R')
df %>% select(Q2_1, boros) %>% 
  lm(Q2_1~., data=.) %>% summary()
#Brooklyn and Manhattan schools have a statistically significant decreased chance of having an arts liaison

#Q22 do you offer a full-year sequence in the arts (middle-school)
q22 <- q_arts %>% .[grepl('Q22', .)] %>% .[grepl('C1', .)]
df %>% select(q22) %>% colSums() %>% 
  as_data_frame() %>% 
  ggplot(aes(x=disc_5, y=value)) +
  geom_bar(stat='identity')
#Three-year sequences in visual arts and music and predominant. There are fewer dance and theater, and much fewer film programs.
#Do schools with film sequences come have wealthier students?
df <- df %>% 
  mutate(Q22_R1_C1 = Q22_R1_C1 %>% as.logical(),
         Q22_R2_C1 = Q22_R2_C1 %>% as.logical(),
         Q22_R3_C1 = Q22_R3_C1 %>% as.logical(),
         Q22_R4_C1 = Q22_R4_C1 %>% as.logical(),
         Q22_R5_C1 = Q22_R5_C1 %>% as.logical())
df %>% select(perc_pov_2017, q22) %>% 
  ggplot(aes(x=perc_pov_2017)) +
  geom_density(aes(color=Q22_R1_C1)) +
  ggtitle('Dance programs')
df %>% select(perc_pov_2017, q22) %>% 
  ggplot(aes(x=perc_pov_2017)) +
  geom_density(aes(color=Q22_R2_C1)) +
  ggtitle('Film programs')
df %>% select(perc_pov_2017, q22) %>% 
  ggplot(aes(x=perc_pov_2017)) +
  geom_density(aes(color=Q22_R3_C1)) +
  ggtitle('Music programs')
df %>% select(perc_pov_2017, q22) %>% 
  ggplot(aes(x=perc_pov_2017)) +
  geom_density(aes(color=Q22_R4_C1)) +
  ggtitle('Theater programs')
df %>% select(perc_pov_2017, q22) %>% 
  ggplot(aes(x=perc_pov_2017)) +
  geom_density(aes(color=Q22_R5_C1)) +
  ggtitle('Visual Arts programs')
#The difference for film programs stands out the most, but that is the discipline with the fewest programs.
#Look at how poverty predicts the presence of an arts program:
df %>%
  glm(Q22_R1_C1~perc_pov_2017, data=., family='binomial') %>% 
  summary()
df %>%
  glm(Q22_R2_C1~perc_pov_2017, data=., family='binomial') %>% 
  summary()
df %>%
  glm(Q22_R3_C1~perc_pov_2017, data=., family='binomial') %>% 
  summary()
#Music programs are significantly negatively related to poverty of students.
df %>%
  glm(Q22_R4_C1~perc_pov_2017, data=., family='binomial') %>% 
  summary()
#Theater programs are significantly negatively related to poverty of students.
df %>%
  glm(Q22_R5_C1~perc_pov_2017, data=., family='binomial') %>% 
  summary()
#Visual arts programs are less significant but still negative.
#Same models, but in a for loop
for (i in q22) {
  temp <- df %>% select(i, perc_pov_2017)
  temp.glm <- glm(unlist(temp[,1])~unlist(temp[,2]), family='binomial')
  print(i)
  print(temp.glm %>% summary())
}

#Q23 number of students to complete a three-year sequence in the arts
q23 <- q_arts %>% .[grepl('Q23', .)]
df %>% select(q23) %>% colSums(na.rm = T) %>% 
  as_data_frame() %>% 
  ggplot(aes(x=disc_5, y=value)) +
  geom_bar(stat='identity')
#The number of students completing a three-year sequence is greates for visual arts and music. About the same number for dance and theater. Much less for film.
for (i in q23) {
  temp <- df %>% select(i, perc_pov_2017)
  temp.lm <- lm(unlist(temp[,1])~unlist(temp[,2]))
  print(i)
  print(temp.lm %>% summary())
}
#Completing a film sequence has a * statistically significant negative relation with poverty. None of the other disciplines have a relation.

#******** Only District 75 **********************
#Q30 number of school-based arts teachers attending professional development
q30 <- q_arts %>% .[grepl('Q30', .)]

#Q31 hours of professional development for school-based arts teachers
q31 <- q_arts %>% .[grepl('Q31', .)]

#Q32 school-based arts teachers professional development offerings
q32 <- q_arts %>% .[grepl('Q32', .)]

#Q33 number of non-arts teachers attending professional development
q33 <- q_arts %>% .[grepl('Q33', .)]

#Q34 hours of professional development for non-arts teachers
q34 <- q_arts %>% .[grepl('Q34', .)]

#Q35 non-arts teachers professional development offerings
q35 <- q_arts %>% .[grepl('Q35', .)]
#******** End District 75 **********************

#Q36 non-DOE arts funding
q36 <- q_arts %>% .[grepl('Q36', .)] %>% .[grepl('C1', .)]
fund_srcs <- c('Cultural organizations',
               'Education association',
               'Federal, state, or city grants',
               'Local business or corporation',
               'Private foundation',
               'PTA/PA',
               'State, county, local arts councils')
df %>% select(q36) %>% colSums() %>% 
  as_data_frame() %>% 
  ggplot(aes(x=reorder(fund_srcs, -value), y=value)) +
  geom_bar(stat='identity') +
  coord_flip()
#Government grants are the most common source of non-DOE funding, followed by cultural organizations, and PTA. Then arts councils, private foundations, educational associations and local business.
#Does poverty predict the different sources of funding?
for (i in q36) {
  temp <- df %>% select(i, perc_pov_2017)
  temp.glm <- glm(unlist(temp[,1])~unlist(temp[,2]), family='binomial')
  print(i); print(summary(temp.glm))
}
#Not statistically significant: Cultural organizations, education associations, government grants, local business, private foundations.
#PTA/PA is negatively associated with poverty at a *** sig. Local arts councils is similar but at a * sig. This could be picking up the effect of neighborhood wealth.

#Q37 funding for the arts
q37 <- q_arts %>% .[grepl('Q37', .)]
df %>% select(q37) %>% colSums() %>% 
  as_data_frame() %>% 
  ggplot(aes(x=reorder(c('Abundant', 'Sufficient', 'Insufficient', 'N/A'), value),
             y=value)) +
  geom_bar(stat='identity')
#Funding is lacking, who would'a thunk it

#Q38 funding over the last three years
q38 <- q_arts %>% .[grepl('Q38', .)]
df %>% select(q38) %>% colSums() %>% 
  as_data_frame() %>% 
  ggplot(aes(x=factor(c('Increased', 'Decreased', 'Remained the same'), levels=c('Increased', 'Remained the same', 'Decreased')),
             y=value)) +
  geom_bar(stat='identity')
#More schools experienced decreased funding than increased funding over the last three years.
#Code q37 and 38 as categorical and look at a mosaic plot.

#Q39 parental involvement
q39 <- q_arts %>% .[grepl('Q39', .)]
par_inv <- c('Attending school arts events',
             'Volunteering in arts programs',
             'Donating arts materials',
             'Other')
df %>% select(Q39_4, Q0_DBN) %>% 
  group_by(Q39_4) %>% count()
#It could be neat to analyze the 'Other' category.
#For now I'll move the comments over and replace them with 1s.
df <- df %>% 
  mutate(Q39_Other = ifelse(Q39_4 == 0, 0, Q39_4),
         Q39_4 = ifelse(Q39_4 == 0, 0, 1))
df %>% select(q39) %>% colSums() %>% 
  as_data_frame() %>% 
  ggplot(aes(x=reorder(par_inv, -value), y=value)) +
  geom_bar(stat='identity') +
  coord_flip()
#Parental participation is most common through attending school events, to be expected. Fewer parents volunteer or donate art materials.
#Is there a relationship between poverty and volunteering in arts programs, Q39_2?
df %>% select(perc_pov_2017, Q39_2) %>% 
  glm(Q39_2~perc_pov_2017, data=., family='binomial') %>% 
  summary()
#There is a strong negative relation between poverty and parental volunteers in arts programs.
#Is there a relationship between poverty and donating arts materials, Q39_3?
df %>% select(perc_pov_2017, Q39_3) %>% 
  glm(Q39_3~perc_pov_2017, data=., family='binomial') %>% 
  summary()
#There is a strong negative relation.

#Q40 arts opportunities at the school and outside of school
q40 <- q_arts %>% .[grepl('Q40', .)]
arts_opp <- c('Artwork exhibits',
              'Concerts',
              'Dance performances',
              'Films',
              'Theater performances',
              'Other')
q40_school <- q40 %>% .[grepl('C1', .)]
q40_outside <- q40 %>% .[grepl('C2', .)]
df %>% select(q40_school) %>% colSums(na.rm = T) %>% 
  as_data_frame() %>% 
  ggplot(aes(x=reorder(arts_opp, -value), y=value)) +
  geom_bar(stat='identity') + coord_flip()
#At school, concerts, dance, theater performances and art exhibits are of decreasing frequency. Films are shown less frequently.
df %>% select(q40_outside) %>% colSums(na.rm = T) %>% 
  as_data_frame() %>% 
  ggplot(aes(x=reorder(arts_opp, -value), y=value)) +
  geom_bar(stat='identity') + coord_flip()
#Outside of school, theater performances and art exhibits are most frequent. Concerts, dance performances and films are less frequent.

#Q41 does your school have an artist in residence
q41 <- q_arts %>% .[grepl('Q41', .)]
df %>% select(Q41_1) %>% sum()
#There are 462 artist-in-residence programs
#Is poverty a good predictor?
df %>% 
  glm(Q41_1~perc_pov_2017, family='binomial', data=.) %>% 
  summary()
#No, there is not a statistically significant coefficient.
#Are boroughs a good predictor?
df %>% select(boros, Q41_1) %>% 
  glm(Q41_1~., family='binomial', data=.) %>% 
  summary()
#No borough has a statistically significant coefficient.

#Q42 artist in residence program discipline
q42 <- q_arts %>% .[grepl('Q42', .)]
df %>% select(q42) %>% colSums() %>% 
  as_data_frame() %>% 
  ggplot(aes(x=disc_4, y=value)) +
  geom_bar(stat='identity')
#Artist-in-residence programs are evenly-distributed across disciplines, excluding film.

#Q43 greatest obstacle to an artist in residence program
q43 <- q_arts %>% .[grepl('Q43', .)]

#Q44 arts education providers, schools could add vendors but I only have one row
#C1 Name of organization
#C2 Name if C1 == 'Other'
#C3 Arts discipline
#C4 Type of service
#C5 Rating for quality of service (1 low - 5 high)
#C6 Number of students provided with service
#C7 Contact hours provided
#C8 Do you plan to engage the organization next year?
#C9 If no, why not
#C10 If C9 == 'Other', specify
q44 <- q_arts %>% .[grepl('Q44', .)]
df %>% select(q44)

#Q45 how/will teachers assess student progress in the arts
q45 <- q_arts %>% .[grepl('Q45_', .)]

#Questions with text answers 46-48
q_text <- q_arts %>% tail(5)
df %>% select(q_text)
#Q46 arts program description
#Q47 contextual information about the school and students
#Q48 name, title and email of the person completing the survey

#Can I create models for arts program metrics from demographics and performance and generate hypothetical data to illustrate the differences brought about by student backgrounds.

df %>% select(q3) %>%
  colSums() %>% as_data_frame() %>%
  ggplot(aes(x=superv_status, y=value)) +
  geom_bar(stat = 'identity') +
  theme_eric()

theme_eric <- function() {
  theme_bw(base_size = 11,
           base_family = 'URWHelvetica')
}
