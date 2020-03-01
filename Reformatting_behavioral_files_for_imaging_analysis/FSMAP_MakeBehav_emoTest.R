rm(list=ls()) 
library(tidyverse)
library(stringr)
library(readr)
library(DataCombine)

## Input ############################################
# Subject names should be consistent for input and output.
data.dir <- '/Users/chendanlei/Dropbox (Partners Healthcare)/NCI_U01_Shared_Data/BehavioralData' # Subjects in this directory.
output.dir <- '/Users/chendanlei/Dropbox (Partners Healthcare)/U01/EmotionAvoidanceTask/BIDS_BehavioralData' # BIDS format. 

emo_subj <- c('14', '15', '16', '22', '23', '28', '30', '34', '37', '39', '43', '45', '50' ,'53', '54', '57', '60', '61', '66','68', '69', '71', '73', '74', '81', '83', '86', '92', '94')
pain_subj <- c('18', '19', '20', '24', '25', '26', '31', '32', '33', '41', '47', '48', '49', '52', '55', '56', '58', '59', '62', '64', '65', '67', '70', '72', '80', '82', '84', '85', '88', '90', '91', '95', '98')

subjReformat <- NaN
subj.sub <- c()
## Load Data ############################################
subj.dirs <- list.dirs(data.dir, recursive = FALSE)
for (xx in 1:length(subj.dirs)) { 
  ## Find Files
  data.files <- list.files(subj.dirs[xx], recursive = FALSE)
  subjID <- paste0('sub-', str_sub(subj.dirs[xx], -3,-1))
  
  if (is.element(TRUE,grepl(str_sub(subjID, -2,-1), pain_subj))) {
    pain_or_emotion = 'pain'
  }else if (is.element(TRUE,grepl(str_sub(subjID, -2,-1), emo_subj))) {
    pain_or_emotion = 'emotion'
  }else{
    next
  }
  
  emo.file <- data.files[(grepl("hybrid_task.*test", data.files) &  !grepl("*original", data.files)) ]
  if (length(emo.file) !=1 ) next else print(subj.dirs[xx])
  ## Load files
  emo_time <- read_delim(paste0(subj.dirs[xx], '/', emo.file),"\t", escape_double = FALSE, col_names = FALSE, skip = 4)      
  emo_time[is.na(emo_time)] <- NaN
  #trial number, CS order, US order, Expectacy Rating ()   
  
  if (pain_or_emotion == 'pain'){
    first_half <- emo_time[,1:floor(15/2)]
    first_half$X8 <- NaN
    second_half <- emo_time[,ceiling(15/2):ncol(emo_time)]
    emo_time <- data.frame(matrix(ncol = 8, nrow = 40))
    for (n in seq(1, nrow(emo_time), 2)){
      emo_time[n,] <- first_half[(n+1)/2,]
      emo_time[n+1,] <- second_half[(n+1)/2,]
    }
  }
  
  #check if files have enough rows and columns
  if (ncol(emo_time) != 8){
    print("subjects with no file: ")
    print(emo.file)
    next
  }
  if (nrow(emo_time) != 40){
    print("subject files need reformatting: ")
    print(emo.file)
    next
  }
  
  colnames(emo_time) <- c('stim_num', 'CS_trial_type', 'US_trial_type', 'ratingType', 'Response', 'ratingOnset', 'ratingRT','US_image')
  
  emo_time$ratingType[emo_time$ratingType=='         1']<-'Expectancy_rating'
  emo_time$ratingType[emo_time$ratingType=='         0']<-'Pleasantness_rating'
  emo_time$US_trial_type[emo_time$US_trial_type=='         1']<-'negative'
  emo_time$US_trial_type[emo_time$US_trial_type=='         0']<-'neutral'
  emo_time$CS_trial_type[emo_time$CS_trial_type=='         1']<-'reinforced'
  emo_time$CS_trial_type[emo_time$CS_trial_type=='         2']<-'unreinforced'
  emo_time[emo_time=='       NaN'] <- NaN
  
  emo_time$US_onset <- NaN
  for (yy in 1:nrow(emo_time)) {
     if (emo_time$ratingType[yy] == 'Pleasantness_rating') {
      emo_time$US_onset[yy] <-  emo_time$US_image[yy]
      emo_time$US_image[yy] <- NaN
    }
  }

  temp <- emo_time
  temp$stim_num <- lapply(temp$stim_num, as.numeric)
  
  emo_time <- data.frame(matrix(ncol = 9, nrow = 140))
  colnames(emo_time) <- c('onset','duration','trial_type','stim_num', 'CS_trial_type', 'US_trial_type', 'ratingResp', 'ratingRT','US_image')
  trial_num <- 0
  for (yy in 1:nrow(emo_time)) {
    if (yy %% 7 == 1 ) {
      trial_num <- trial_num+1
      emo_time$duration[yy] <- 2
      emo_time$trial_type[yy] <- 'CS'
      emo_time$stim_num[yy] <- trial_num
      emo_time$CS_trial_type[yy] <- temp$CS_trial_type[temp$stim_num==emo_time$stim_num[yy]][1]
    }else if (yy %% 7 == 2) {
      emo_time$duration[yy] <- 2
      emo_time$trial_type[yy] <- 'expRating'
      emo_time$stim_num[yy] <- trial_num
      emo_time$ratingResp[yy] <- temp$Response[temp$stim_num==emo_time$stim_num[yy] & temp$ratingType=='Expectancy_rating']
      emo_time$ratingRT[yy] <- temp$ratingRT[temp$stim_num==emo_time$stim_num[yy] & temp$ratingType=='Expectancy_rating']
    }else if (yy %% 7 == 3) {
      emo_time$trial_type[yy] <- 'anticipation'
      emo_time$stim_num[yy] <- trial_num
    }else if (yy %% 7 == 4) {
      emo_time$duration[yy] <- 2
      emo_time$trial_type[yy] <- 'US'
      emo_time$stim_num[yy] <- trial_num
      emo_time$US_trial_type[yy] <- temp$US_trial_type[temp$stim_num==emo_time$stim_num[yy]][1]
      emo_time$US_image[yy] <- temp$US_image[temp$stim_num==emo_time$stim_num[yy] & temp$ratingType=='Expectancy_rating']
    }else if (yy %% 7 == 5) {
      emo_time$duration[yy] <- 2
      emo_time$trial_type[yy] <- 'unpRating'
      emo_time$stim_num[yy] <- trial_num
      emo_time$ratingResp[yy] <- temp$Response[temp$stim_num==emo_time$stim_num[yy] & temp$ratingType=='Pleasantness_rating']
      emo_time$ratingRT[yy] <- temp$ratingRT[temp$stim_num==emo_time$stim_num[yy] & temp$ratingType=='Pleasantness_rating']
    }else if (yy %% 7 == 6) {
      emo_time$trial_type[yy] <- 'anticipation_period'
      emo_time$stim_num[yy] <- trial_num
      emo_time$CS_trial_type[yy] <- temp$CS_trial_type[temp$stim_num==emo_time$stim_num[yy]][1]
    }else{
      emo_time$duration[yy] <- 2+2
      emo_time$trial_type[yy] <- 'CS_rating_period'
      emo_time$stim_num[yy] <- trial_num
      emo_time$CS_trial_type[yy] <- temp$CS_trial_type[temp$stim_num==emo_time$stim_num[yy]][1]
    }
  }
  
  emo_time$onset <- NaN
  emo_time$onset[emo_time$trial_type=='CS'] <- temp$ratingOnset[temp$ratingType=='Expectancy_rating']-2
  emo_time$onset[emo_time$trial_type=='expRating'] <- temp$ratingOnset[temp$ratingType=='Expectancy_rating']
  emo_time$onset[emo_time$trial_type=='anticipation'] <- temp$ratingOnset[temp$ratingType=='Expectancy_rating']+2
  emo_time$onset[emo_time$trial_type=='US'] <- temp$US_onset[temp$ratingType=='Pleasantness_rating']
  emo_time$onset[emo_time$trial_type=='unpRating'] <- temp$ratingOnset[temp$ratingType=='Pleasantness_rating']
  emo_time$onset[emo_time$trial_type=='anticipation_period'] <- emo_time$onset[emo_time$trial_type=='CS']
  emo_time$onset[emo_time$trial_type=='CS_rating_period'] <- emo_time$onset[emo_time$trial_type=='CS']
  emo_time$onset <- as.numeric(emo_time$onset)
  emo_time$duration[emo_time$trial_type=='anticipation'] <- as.numeric(emo_time$onset[emo_time$trial_type=='US']) - as.numeric(emo_time$onset[emo_time$trial_type=='anticipation'])
  emo_time$duration[emo_time$trial_type=='anticipation_period'] <- emo_time$duration[emo_time$trial_type=='anticipation'] + emo_time$duration[emo_time$trial_type=='CS_rating_period']
  emo_time$duration <- as.numeric(emo_time$duration)
  
  emo_time$ratingRT <- as.character(emo_time$ratingRT)
  emo_time$ratingResp <- as.numeric(emo_time$ratingResp)
  emo_time$ratingResp <- as.character(emo_time$ratingResp)
  emo_time$duration <- as.character(emo_time$duration)
  emo_time$onset <- as.numeric(emo_time$onset)
  emo_time$onset <- as.character(emo_time$onset)
  emo_time[emo_time=='       NaN'] <- NaN
  emo_time$US_image[is.na(emo_time$US_image)] <- 'NaN'
  emo_time[is.na(emo_time)] <- NaN
  
  #adjust for 10s disdaq delay
  emo_time$onset <- as.numeric(emo_time$onset)+10
  
  if (sum(emo_time$onset=='NaN')>0){
    subjReformat <- c(subjReformat,subjID)
  }
  
  # #change the order of the columns (move the last three cols to first)
  # emo_time<- emo_time[,c(which(colnames(emo_time)=="onset"),which(colnames(emo_time)=="duration"),which(colnames(emo_time)=="trial_type"), which(colnames(emo_time)=="US_trial_type"), which(colnames(emo_time)=="CS_trial_type"), which(colnames(emo_time)!="onset" & colnames(emo_time)!="duration" & colnames(emo_time)!="trial_type" & colnames(emo_time)!="CS_trial_type" & colnames(emo_time)!="US_trial_type") )]
  
  if (pain_or_emotion == 'emotion'){
    #save the file
    if (is.element(TRUE,grepl(str_sub(subjID, -2,-1),emo_subj))) {
      # dir.create(paste0(output.dir, '/', subjID))
      write.table(emo_time, file=paste0(output.dir, '/', subjID, '/', subjID, '_task-emo2_events.tsv'), quote=FALSE,
                  sep='\t', row.names=FALSE)
    }
  }
  
  if (pain_or_emotion == 'pain'){
    if (is.element(TRUE,grepl(str_sub(subjID, -2,-1), pain_subj))) {
      dir.create(paste0(output.dir, '/', subjID))
      write.table(emo_time, file=paste0(output.dir, '/', subjID, '/', subjID, '_task-pain2_events.tsv'), quote=FALSE,
                  sep='\t', row.names=FALSE)
    }
  }
  
  # else
  #   write.table(emo_time_run, file=paste0(output.dir, '/', subjID, '/', subjID, '_task-pain3_run-0',zz,'_events.tsv'), quote=FALSE,
  #               sep='\t', row.names=FALSE)
  
  # read_delim(paste0(output.dir, '/', subjID, '/', subjID, '_task-emo2_events.tsv'),"\t", escape_double = FALSE, col_names = FALSE)

}
