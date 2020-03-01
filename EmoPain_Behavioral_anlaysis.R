library(R.matlab)
library(lme4)
library(rlist)
library(arm)
library(nlme)
library(lmerTest)
library(ggplot2)
library(effsize)

path <- '/Users/chendanlei/Google Drive/U01/EmotionAvoidanceTask/behavioral analysis'
# pathname <- file.path(path, "pain.mat")
pathname <- file.path(path, "emo.mat")

subj_mean <- readMat(pathname)$Routput
num_subj <- ncol(subj_mean)/20
subj_label <- as.factor(rep(c(1:num_subj),length(subj_mean)/num_subj))

#Expectancy rating
subj_mean_exp <- subj_mean[1:(num_subj*4)]
subj_label_testing <- subj_label[1:(num_subj*4)]
trial_type <- as.factor(c(rep('CS+Acq',each=num_subj),rep('CS-Acq',each=num_subj),rep('CS+Test',each=num_subj),rep('CS-Test',each=num_subj)))
trial_type<- factor(trial_type,levels = c('CS+Acq', 'CS-Acq', 'CS+Test', 'CS-Test'))
CS_type <- as.factor(c(rep('CS+',each=num_subj),rep('CS-',each=num_subj),rep('CS+',each=num_subj),rep('CS-',each=num_subj)))
CS_type <- factor(CS_type,levels = c('CS+','CS-'))
Phase_type <- as.factor(c(rep('Acq',each=num_subj),rep('Acq',each=num_subj),rep('Test',each=num_subj),rep('Test',each=num_subj)))
emoTest <- data.frame("Expectancy_Rating"=subj_mean_exp, "subj"=subj_label_testing,"condition"=trial_type)

ggplot(emoTest_select,aes(condition,Expectancy_Rating))+
  stat_summary(fun.data=mean_se, geom="bar", size = 0.5)+ 
  geom_violin(trim=FALSE, alpha = 0.1, size=0.1) +
  geom_point(alpha = 0.15, size = 1.5) +
  geom_line(data = emoTest_select, aes(condition,Expectancy_Rating, group=subj_label_testing), alpha = 0.1, size = 0.5) +
  stat_summary(fun.data=mean_se, geom="line", alpha = 0.15, colour = NA)+
  stat_summary(fun.data=mean_se, geom="errorbar", size = 0.5, width=0.2)+
  stat_summary(fun.y=mean, geom="point", size = 1.5, alpha = 0.3)+
  ggtitle("Testing Phase")

emoTest_select <- emoTest[(emoTest$condition=='CS+Acq' | emoTest$condition=='CS-Acq'),]
levels(emoTest_select$condition)[levels(emoTest_select$condition)=="CS+Acq"] <- "CS+"
levels(emoTest_select$condition)[levels(emoTest_select$condition)=="CS-Acq"] <- "CS-"
emoTest_select$condition <- factor(emoTest_select$condition)
p <- ggplot(emoTest_select,aes(condition,Expectancy_Rating,fill=condition))+
  stat_summary(fun.data=mean_se, geom="bar", size = 0.5)+
  scale_fill_manual(values = alpha(c('gold','goldenrod2')))+
  scale_colour_manual(values = alpha(c('gold','goldenrod2')))+
  scale_shape_manual(values = alpha(c('gold','goldenrod2')))+  geom_violin(trim=TRUE, alpha = 0.1, size=0.8, colour = "dark grey") +
  geom_point(alpha = 0.15, size = 1.5, colour = "dark grey") +
  geom_line(data = emoTest_select, aes(condition,Expectancy_Rating, group=subj), alpha = 0.3, size = 0.8,colour = "dark grey") +
  stat_summary(fun.data=mean_se, geom="line", alpha = 0.3, colour = "dark grey")+
  stat_summary(fun.data=mean_se, geom="errorbar", size = 0.8, width=0.2, colour = "dark grey")+
  stat_summary(fun.y=mean, geom="point", size = 1.5, alpha = 0.3, colour = "dark grey")+
  ggtitle("")+
  theme(panel.grid.major = element_blank(),
        panel.grid.minor = element_blank(),
        panel.background = element_rect(fill = "transparent",colour = NA),
        plot.background = element_rect(fill = "transparent",colour = NA),
        axis.line = element_line(colour = "white",size=1),
        axis.text=element_text(size=18,colour = "white"),
        axis.title=element_text(size=18,face="bold",colour = "white"))+
  theme(legend.position="none", axis.title.x = element_text(colour = "white"),axis.title.y = element_text(colour = "white"))+
  xlab("Condition") + ylab("Expectacy Rating")+ theme(legend.title = element_blank())
p
ggsave("/Users/chendanlei/Desktop/masters/1.png", width = 100, height = 120, units = c("mm"), p, bg = "transparent")


#repeated measure ANOVA https://www.r-bloggers.com/how-to-do-repeated-measures-anovas-in-r/
summary(aov(Expectancy_Rating ~ CS_type * Phase_type + Error(subj_label_testing/(CS_type * Phase_type)), data=emoTest,na.action = na.exclude))
anova(fit2<-lmer(Expectancy_Rating ~ CS_type * Phase_type + (1|subj_label_testing), data=emoTest,na.action = na.exclude))
#cohen's d
cohen.d(emoTest$Expectancy_Rating,CS_type)
cohen.d(emoTest$Expectancy_Rating[Phase_type=='Acq'],CS_type[Phase_type=='Acq'])
cohen.d(emoTest$Expectancy_Rating[Phase_type=='Test'],CS_type[Phase_type=='Test'])
cohen.d(emoTest$Expectancy_Rating,Phase_type)

#Unpleasantness rating
subj_mean_unp <- subj_mean[((num_subj*4)+1):((num_subj*4)+(num_subj*4))]
subj_label_unp <- subj_label[((num_subj*4)+1):((num_subj*4)+(num_subj*4))]
trial_type <- as.factor(c(rep('CS+Acq',each=num_subj),rep('CS-Acq',each=num_subj),rep('CS+Test',each=num_subj),rep('CS-Test',each=num_subj)))
trial_type<- factor(trial_type,levels = c('CS+Acq', 'CS-Acq', 'CS+Test', 'CS-Test'))
CS_type <- as.factor(c(rep('CS+',each=num_subj),rep('CS-',each=num_subj),rep('CS+',each=num_subj),rep('CS-',each=num_subj)))
CS_type <- factor(CS_type,levels = c('CS+','CS-'))
Phase_type <- as.factor(c(rep('Acq',each=num_subj),rep('Acq',each=num_subj),rep('Test',each=num_subj),rep('Test',each=num_subj)))
emoTest <- data.frame("Unpleasantness_Rating"=subj_mean_unp, "subj"=subj_label_testing,"condition"=trial_type)

ggplot(emoTest,aes(condition,Unpleasantness_Rating))+
  stat_summary(fun.data=mean_se, geom="bar", size = 0.5)+ 
  geom_violin(trim=FALSE, alpha = 0.1, size=0.1) +
  geom_point(alpha = 0.15, size = 1.5) +
  geom_line(data = emoTest, aes(condition,Unpleasantness_Rating, group=subj_label_unp), alpha = 0.1, size = 0.5) +
  stat_summary(fun.data=mean_se, geom="line", alpha = 0.15, colour = NA)+
  stat_summary(fun.data=mean_se, geom="errorbar", size = 0.5, width=0.2)+
  stat_summary(fun.y=mean, geom="point", size = 1.5, alpha = 0.3)+
  ggtitle("Testing Phase")

#repeated measure ANOVA https://www.r-bloggers.com/how-to-do-repeated-measures-anovas-in-r/
summary(aov(Unpleasantness_Rating ~ CS_type * Phase_type + Error(subj_label_testing/(CS_type * Phase_type)), data=emoTest,na.action = na.exclude))
anova(fit2<-lmer(Unpleasantness_Rating ~ CS_type * Phase_type + (1|subj_label_testing), data=emoTest,na.action = na.exclude))
#cohen's d
cohen.d(emoTest$Unpleasantness_Rating,CS_type)
cohen.d(emoTest$Unpleasantness_Rating[Phase_type=='Acq'],CS_type[Phase_type=='Acq'])
cohen.d(emoTest$Unpleasantness_Rating[Phase_type=='Test'],CS_type[Phase_type=='Test'])
cohen.d(emoTest$Unpleasantness_Rating,Phase_type)

#switching behavior
subj_mean_switch <- subj_mean[((num_subj*4*2)+1):((num_subj*4*2)+(num_subj*6*2))]
subj_label_switch <- subj_label[((num_subj*4*2)+1):((num_subj*4*2)+(num_subj*6*2))]
trial <- as.factor(c(rep('1',each=num_subj),rep('2',each=num_subj),rep('3',each=num_subj),rep('4',each=num_subj),rep('5',each=num_subj),rep('6',each=num_subj),
                          rep('1',each=num_subj),rep('2',each=num_subj),rep('3',each=num_subj),rep('4',each=num_subj),rep('5',each=num_subj),rep('6',each=num_subj)))
CS_type <- as.factor(c(rep('CS-',each=num_subj*6),rep('CS+',each=num_subj*6)))
emoTest <- data.frame("switching_prob"=subj_mean_switch, "subj"=subj_label_switch,"trials"=trial, "CS_type"=CS_type)
emoTest <- emoTest[(emoTest$trials=='1') | (emoTest$trials=='2') | (emoTest$trials=='3') | (emoTest$trials=='4') | (emoTest$trials=='5'),]
emoTest$trials <- as.numeric(emoTest$trials)
# emoTest$trials <- numeric(emoTest$trials)

p <- ggplot(data = emoTest, aes(trials,switching_prob, group=CS_type, col=CS_type, fill=CS_type))+
  # geom_point(size = 0.5, alpha = 0.5)+
  stat_summary(fun.data=mean_se, geom="ribbon", alpha = 0.3, colour = NA)+
  stat_summary(fun.data=mean_se, geom="line", size = 1)+
  stat_summary(fun.y=mean, geom="point", size = 1.5)+
  ggtitle("")+ 
  scale_fill_manual(values = alpha(c('gold','goldenrod2')))+
  scale_colour_manual(values = alpha(c('gold','goldenrod2')))+
  scale_shape_manual(values = alpha(c('gold','goldenrod2')))+
  theme(panel.grid.major = element_blank(), 
        panel.grid.minor = element_blank(),
        panel.background = element_rect(fill = "transparent",colour = NA),
        plot.background = element_rect(fill = "transparent",colour = NA), 
        axis.line = element_line(colour = "white",size=1),
        axis.text=element_text(size=18,colour = "white"),
        axis.title=element_text(size=18,face="bold",colour = "white"),
        legend.text = element_text(size=18,face="bold",colour = "white"),
        legend.background = element_rect(fill="transparent"),
        legend.key = element_rect(fill = "transparent", color = NA))+
  xlab("Trials") + ylab("Probability of Switch")+ theme(legend.title = element_blank())
p
ggsave("/Users/chendanlei/Google Drive/masters/2.png", width = 150, height = 120, units = c("mm"), p, bg = "transparent")

summary(aov(switching_prob ~ trials * CS_type + Error(subj/(trials * CS_type)), data=emoTest,na.action = na.exclude))
anova(fit2<-lmer(switching_prob ~ trials * CS_type + (1|subj), data=emoTest,na.action = na.exclude))
#cohen's d
cohen.d(emoTest$switching_prob,emoTest$trials)
cohen.d(emoTest$switching_prob,emoTest$CS_type)
cohen.d(emoTest$switching_prob,emoTest$CS_type)








poly_model <- lm(switching_prob ~ poly(trials, degree = 2), data = emoTest[emoTest$CS_type=='CS+',])
poly_predict <- data.frame(trial = with(emoTest[emoTest$CS_type=='CS+',], seq(min(trials), max(trials), length.out=2000))) 
poly_predict$switching_prob_CSplus <- predict(poly_model, newdata = data.frame(trials = poly_predict$trial))
poly_model <- lm(switching_prob ~ poly(trials, degree = 2), data = emoTest[emoTest$CS_type=='CS-',])
poly_predict$switching_prob_CSminus <- predict(poly_model, newdata = data.frame(trials = poly_predict$trial))
ggplot(data = NULL)+
  geom_point(data=emoTest, aes(trials,switching_prob,colour = CS_type), size = 0.5, alpha = 0.5)+
  stat_summary(data=emoTest, aes(trials,switching_prob, group=CS_type, col=CS_type), fun.data=mean_se, geom="errorbar",width=0.1,  size = 0.5)+
  stat_summary(data=emoTest, aes(trials,switching_prob, group=CS_type, col=CS_type), fun.data=mean_se, geom="line", size = 0.5)+
  stat_summary(data=emoTest, aes(trials,switching_prob, group=CS_type, col=CS_type), fun.y=mean, geom="point", size = 2)+
  geom_line(data=poly_predict,aes(x=trial, y=switching_prob_CSplus),colour='#00BFC4',linetype = "solid", size = 1)+
  geom_line(data=poly_predict,aes(x=trial, y=switching_prob_CSminus),colour='#F8766D',linetype = "solid", size = 1)

#repeated measure ANOVA https://www.r-bloggers.com/how-to-do-repeated-measures-anovas-in-r/
summary(aov(switching_prob ~ trials * CS_type + Error(subj/(trials * CS_type)), data=emoTest,na.action = na.exclude))
anova(fit2<-lmer(switching_prob ~ trials * CS_type + (1|subj), data=emoTest,na.action = na.exclude))



#switching behavior logistic regression
# logit regression see: https://stats.idre.ucla.edu/r/dae/logit-regression/
pathname <- file.path(path, "logit_mtx.mat")
logit_mtx <- readMat(pathname)$logistic.regression.mtx.all
logit_df <- data.frame("switch"=logit_mtx[,1], "CS_type"=logit_mtx[,2],"trials"=logit_mtx[,3],"subj"=logit_mtx[,4])
logit_df$CS_type <- as.factor(logit_df$CS_type)
logit_df$trials <- as.numeric(logit_df$trials)
# logit_df$trials <- as.factor(logit_df$trials)
logit_df$subj <- as.factor(logit_df$subj)
# logit_df=logit_df[logit_df$CS_type=='0',]
aggregate(logit_df$switch,by=(list(logit_df$trials)), FUN=sum)$x/aggregate(logit_df$switch,by=(list(logit_df$trials)), FUN=length)$x

ggplot(logit_df, aes(trials, switch, group=CS_type,colour=CS_type)) +
  geom_jitter(position = position_jitter(width = 0.2, height = 0.2)) +
  stat_summary(fun.data=mean_se, geom="line", size = 0.5)

mylogit <- glm(switch ~ trials + CS_type, data = logit_df, family = "binomial")
summary(mylogit)

# logit_df1 <- with(logit_df, data.frame(trials = mean(trials), CS_type = factor(rep(c(0,1),each=6))))
logit_df1 <- with(logit_df, data.frame(trials = rep(factor(1:6),2), CS_type = factor(rep(0:1,each=6)) ))
logit_df1$trialP <- predict(mylogit, newdata = logit_df1, type = "response")
logit_df1

# logit_df2 <- with(logit_df1, data.frame(trials = rep(seq(from = 1, to = 6, length.out = 100),2), CS_type = factor(rep(0:1, each = 100)) ))
logit_df2 <- with(logit_df, data.frame(trials = rep(c(1:6),2), CS_type = rep(factor(0:1),each=6) ))

logit_df3 <- cbind(logit_df2, predict(mylogit, newdata = logit_df2, type = "link",se = TRUE))
logit_df3 <- within(logit_df3, {
  PredictedProb <- plogis(fit)
  LL <- plogis(fit - (1.96 * se.fit))
  UL <- plogis(fit + (1.96 * se.fit))
})
# head(logit_df3)
ggplot(logit_df3, aes(x = trials, y = PredictedProb)) + geom_ribbon(aes(ymin = LL,ymax = UL, fill = CS_type), alpha = 0.2) + geom_line(aes(colour = CS_type),size = 1)
emoTest$trials = as.numeric(emoTest$trials)
ggplot(data = logit_df3, aes(x = trials, y = PredictedProb, group=CS_type)) +
  # geom_ribbon(aes(ymin = LL,ymax = UL, fill = CS_type), alpha = 0.15)+ 
  geom_line(aes(colour = CS_type), size = 1)+
  stat_summary(data = emoTest, aes(x=trials, y=switching_prob, group=CS_type, col=CS_type), fun.data=mean_se, geom="ribbon", alpha = 0.15, colour = NA)+
  # stat_summary(data = emoTest, fun.data=mean_se, geom="line", size = 0.5)+
  stat_summary(data = emoTest, aes(x=trials, y=switching_prob, group=CS_type, col=CS_type), fun.y=mean, geom="point", size = 1.5)+
  theme(axis.line = element_line(colour = "black"),
        axis.text=element_text(size=16),
        axis.title=element_text(size=16),
        plot.title = element_text(size=16,face="bold")) + 
  ggtitle("Avoidance learning")

logLik(mylogit)

ggplot(data = logit_df3, aes(x = trials, y = PredictedProb, group=CS_type)) +
  # geom_ribbon(aes(ymin = LL,ymax = UL, fill = CS_type), alpha = 0.15)+ 
  geom_line(aes(colour = CS_type), size = 0.5,linetype = "dashed")+
  geom_jitter(data = logit_df, aes(trials, switch, group=CS_type,colour=CS_type), position = position_jitter(width = 0.2, height = 0.2)) +
  stat_summary(data = logit_df, aes(trials, switch, group=CS_type,colour=CS_type), fun.data=mean_se, geom="line", size = 0.5)

############## draw individual file
pathname <- file.path('/Users/chendanlei/Google Drive/U01/EmotionAvoidanceTask/behavioral analysis/hybrid_conditioning', 'RandomWalk2.mat')
#each column is #of subject median RT in each block (#of subject*10)
temp <- readMat(pathname)$X
randomWalk <- data.frame("trial"=rep(seq(1:120),2),"ProbReinf"=c(temp[,1],temp[,2]),"condition"=c(rep('P(Reinf):Circle',120),rep('P(Reinf):Triangle',120)))
randomWalk$trial <- as.numeric(randomWalk$trial)
temp <- readMat('/Users/chendanlei/Google Drive/masters/s23dat.mat')$dat
s22dat1 <- data.frame("trial"=c(which(temp[,1]==1), which(temp[,2]==1), which(temp[,3]==1), which(temp[,3]==0) ),
                      "ProbReinf"=c(rep(6,length(which(temp[,1]==1))), rep(1,length(which(temp[,2]==1))), rep(3,length(which(temp[,3]==1))), rep(3,length(which(temp[,3]==0))) ),
                      "condition"=c(rep("Reinforced trial",length(which(temp[,1]==1))), rep("Active trial",length(which(temp[,2]==1))), rep("Chose circle",length(which(temp[,3]==1))), rep("Chose triangle",length(which(temp[,3]==0))) ))
s22dat1$trial <- as.numeric(s22dat1$trial)

randomWalk <- randomWalk[randomWalk$trial<=60,]
s22dat1 <- s22dat1[s22dat1$trial<=60,]

p<-ggplot()+
  geom_line(data=randomWalk, aes(x=trial, y=ProbReinf,col=condition),size=2)+
  scale_color_manual(values=c("darkolivegreen2", "thistle2"))+
  theme(panel.grid.major = element_blank(), 
        panel.grid.minor = element_blank(),
        panel.background = element_rect(fill = "transparent",colour = NA),
        plot.background = element_rect(fill = "transparent",colour = NA), 
        axis.line = element_line(colour = "white",size=1),
        axis.text=element_text(size=18,colour = "white"),
        axis.title=element_text(size=18,face="bold",colour = "white"),
        legend.text = element_text(size=18,face="bold",colour = "white"),
        legend.background = element_rect(fill="transparent"),
        legend.key = element_rect(fill = "transparent", color = NA))+
  xlim(1, 65)+ ylim(0,100)+ 
  # theme(legend.position='none')+
  xlab("Trials") + ylab("Prob(Reinf)")+ theme(legend.title = element_blank())
p
ggsave("/Users/chendanlei/Google Drive/masters/3.png", width = 180, height = 100, units = c("mm"), p, bg = "transparent")

p<-ggplot()+
  geom_point(data = s22dat1, aes(x=trial, y = ProbReinf,size=condition,shape=condition,col=condition))+
  scale_shape_manual(values = c(19,16,17,15), name=NA, labels= c("Active trial","Chose circle","Chose triangle","Reinforced trial"))+
  scale_size_manual(values=c(0.5,2.5,2.5,1.5), name=NA, labels= c("Active trial","Chose circle","Chose triangle","Reinforced trial"))+
  scale_color_manual(values=c("white", "darkolivegreen2", "thistle2", "white"), 
                     name=NA, labels= c("Active trial","Chose circle","Chose triangle","Reinforced trial"))+
  theme(panel.grid.major = element_blank(), 
        panel.grid.minor = element_blank(),
        panel.background = element_rect(fill = "transparent",colour = NA),
        plot.background = element_rect(fill = "transparent",colour = NA), 
        axis.line = element_line(colour = "white",size=1),
        axis.text=element_text(size=18,colour = "white"),
        axis.title=element_text(size=18,face="bold",colour = "white"),
        legend.text = element_text(size=18,face="bold",colour = "white"),
        legend.background = element_rect(fill="transparent"),        
        legend.key = element_rect(fill = "transparent", color = NA))+
  xlim(1, 65)+ ylim(0,100)+ 
  theme(legend.position='none')+
  xlab("Trials") + ylab("Prob(Reinf)")+ theme(legend.title = element_blank())
p
ggsave("/Users/chendanlei/Google Drive/masters/4.png", width = 180, height = 100, units = c("mm"), p, bg = "transparent")
