rm(list=ls()) 
library(tidyverse)
library(stringr)
library(readr)

## Input ############################################
# Subject names should be consistent for input and output.
data.dir <- '/Users/chendanlei/Dropbox (Partners Healthcare)/NCI_U01_Shared_Data/BehavioralData' # Subjects in this directory.
output.dir <- '/Users/chendanlei/Dropbox (Partners Healthcare)/U01/EmotionAvoidanceTask/BIDS_BehavioralData' # BIDS format. 

# Emotion P3
q1 <- 'sleepy-awake' # -2 2
q2 <- 'fatigued-energetic' # -2 2
q3 <- 'bored-engaged' # -2 2
q4 <- 'unpleasant-pleasant' # -2 2
q5 <- 'tense-calm' # -2 2
q6 <- 'restless-relaxed' # -2 2
q7 <- 'task_demanding: none-extremely' # 1  5
q8 <- 'task_resouces: lacking-plentiful' # 1  5
q9 <- 'task_performance: poor-well' # 1  5
#post
q10 <- 'task_demanding: not-extremely' # 1  5
q11 <- 'task_resources: lacking-plentiful' # 1  5
q12 <- 'task_performance: poorly-well' # 1  5

emo_subj <- c('14', '15', '16', '22', '23', '28', '30', '34', '37', '39', '43', '45', '50' ,'53', '54', '57', '60', '61', '66','68', '69', '71', '73', '74', '81', '83', '86', '92', '94')
pain_subj <- c('18', '19', '20', '24', '25', '26', '31', '32', '33', '41', '47', '48', '49', '52', '55', '56', '58', '59', '62', '64', '65', '67', '70', '72', '80', '82', '84', '85', '88', '90', '91', '95', '98')
#waiting for pre-processing 43 47 50 52 71 98

subj.sub <- c()
## Load Data ############################################
subj.dirs <- list.dirs(data.dir, recursive = FALSE)
for (xx in 1:length(subj.dirs)) { 
  # for eachs subject directory #TODO - this is currently messing up  on 003, 004, who didn't respond at all or missing a col somewhere and failed this script.

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
  
  emo.files <- data.files[(grepl("hybrid_task.*avoidance", data.files) &  !grepl("*original", data.files)) | grepl("hybrid_task.*postRunQuestions", data.files)]# emo names differ across files, so match broadly.
  if (length(emo.files) !=2 ) next else print(subj.dirs[xx])
  emo.chars <- nchar(emo.files) # then get characters for each
  ## Load files
  emo_post_q <- read_delim(paste0(subj.dirs[xx], '/', emo.files[which(emo.chars == max(emo.chars))]), # longest match is post-questionnaire
                           "\t", escape_double = FALSE, col_names = FALSE, trim_ws = TRUE) 
  # if survey run multiple times, take the last (12*6+9=)81 rows.
  if (nrow(emo_post_q) > 81) {
    emo_post_q <- emo_post_q[-(1:(nrow(emo_post_q)-81)),]
  } 
  colnames(emo_post_q) <- c('Qnum', 'NA1', 'Qnum2', 'Resp', 'NA2', 'onset', 'RT')
  
  # add pre=post designation.
  emo_post_q$pre_post <- NaN
  emo_post_q$pre_post[is.nan(emo_post_q$onset)] <- 'pre'
  emo_post_q$pre_post[!is.nan(emo_post_q$onset)] <- 'post'
  
  # replace question text.
  emo_post_q <- replace(emo_post_q, emo_post_q == 'Question1', q1)
  emo_post_q <- replace(emo_post_q, emo_post_q == 'Question2', q2)
  emo_post_q <- replace(emo_post_q, emo_post_q == 'Question3', q3)
  emo_post_q <- replace(emo_post_q, emo_post_q == 'Question4', q4)
  emo_post_q <- replace(emo_post_q, emo_post_q == 'Question5', q5)
  emo_post_q <- replace(emo_post_q, emo_post_q == 'Question6', q6)
  emo_post_q <- replace(emo_post_q, emo_post_q == 'Question7', q7)
  emo_post_q <- replace(emo_post_q, emo_post_q == 'Question8', q8)
  emo_post_q <- replace(emo_post_q, emo_post_q == 'Question9', q9)
  emo_post_q <- replace(emo_post_q, emo_post_q == 'Question10', q10)
  emo_post_q <- replace(emo_post_q, emo_post_q == 'Question11', q11)
  emo_post_q <- replace(emo_post_q, emo_post_q == 'Question12', q12)
  emo_post_q <- emo_post_q[,c('Qnum', 'Qnum2', 'Resp', 'RT', 'pre_post')]
  emo_post_q$Question <- paste0(emo_post_q$pre_post, '_', emo_post_q$Qnum2)

  emo_post_q$task <- 'emo'
  emo_post_q$subj <- subjID
  if (exists("emo_behav")) {
    emo_behav <- rbind(emo_behav, emo_post_q)
  } else {
    emo_behav <- emo_post_q
  }
  
  # get timing file
  # tryCatch(
  #   expr = {
  #     emo_time <- read_delim(paste0(subj.dirs[xx], '/', emo.files[which(emo.chars == min(emo.chars))]), # shortest match is timing data.
  #                            "\t", escape_double = FALSE, col_names = FALSE, skip = 4)# the last col is us_conset that doesn't have a col name
  #     
  #     emo_time <- drop_na(emo_time)# remove rows with NA values, which should be all the unnecessary header files
  #     colnames(emo_time) <- c('stim_num','participant_made_choice','CS_stim_order_on_screen','CS_onset','decision_onset','screen_side_choice','RT','US_reinforcement','choice','image','US_onset')
  #   },
  #   error = function(e){
  #   }
  # )
  
  rm(emo_time) 

  emo_time <- read_delim(paste0(subj.dirs[xx], '/', emo.files[which(emo.chars == min(emo.chars))]), # shortest match is timing data.
                            "\t", escape_double = FALSE, col_names = FALSE, skip = 4)# the last col is us_conset that doesn't have a col name
  
  emo_time <- drop_na(emo_time)# remove rows with NA values, which should be all the unnecessary header files

  if (ncol(emo_time) == 11){
    colnames(emo_time) <- c('stim_num','participant_made_choice','CS_stim_order_on_screen','CS_onset','decision_onset','screen_side_choice','RT','US_reinforcement','choice','image','US_onset')
  }else if (ncol(emo_time) == 10){
    colnames(emo_time) <- c('stim_num','participant_made_choice','CS_stim_order_on_screen','CS_onset','decision_onset','screen_side_choice','RT','US_reinforcement','choice','US_onset')
    emo_time <- emo_time[- grep("Stimulus_Nr", emo_time$stim_num),] # remove original header
  }
  
  if (nrow(emo_time) != 120) next #in case previous if statements still don't catch all the errors

  # add run_num designation.
  emo_time$run_num <- NaN
  emo_time$run_num<- rep(c(1:5), each=24) #24trials in each of the 5 runs
  
  # combine dataframes.
  emo_post_resp <- data.frame(matrix(unlist(emo_post_q$Resp), ncol=length(emo_post_q$Resp)))
  emo_post_resp <- emo_post_resp[rep(seq_len(nrow(emo_post_resp)), each=nrow(emo_time)),]
  colnames(emo_post_resp) <- paste0('resp_', emo_post_q$Question)
  
  emo_post_RT <- data.frame(matrix(unlist(emo_post_q$RT), ncol=length(emo_post_q$RT)))
  emo_post_RT <- emo_post_RT[rep(seq_len(nrow(emo_post_RT)), each=nrow(emo_time)),]
  colnames(emo_post_RT) <- paste0('RT_', emo_post_q$Question)
  
  emo_time <- cbind(emo_time, emo_post_resp, emo_post_RT)
  
  #remove rows that contains CS onset as Nans
  emo_time <- emo_time[!grepl("Nan", emo_time$CS_onset),]
  
  # re-arrange to align all the onset colums
  emo_time <- emo_time[rep(seq_len(nrow(emo_time)), each = 5), ]# repeat all rows 5 times (5 different onsets)
  
  rownames(emo_time) <- 1:nrow(emo_time)
  emo_time$onset <- NaN
  emo_time$duration <- NaN
  emo_time$trial_type <- NaN
  for (yy in 1:nrow(emo_time)) {
    if (yy %% 5 == 1 ) {
      emo_time$onset[yy] = emo_time$CS_onset[yy]
      emo_time$duration[yy] <- 1
      emo_time$trial_type[yy] <- 'CS'
    }else if (yy %% 5 == 2) {
      emo_time$onset[yy] = emo_time$CS_onset[yy]
      emo_time$duration[yy] <- 1
      emo_time$trial_type[yy] <- 'information'
    }else if (yy %% 5 == 3) {
      emo_time$onset[yy] = emo_time$decision_onset[yy]
      emo_time$duration[yy] <- 2
      emo_time$trial_type[yy] <- 'decision'
    }else if (yy %% 5 == 4) {
      emo_time$onset[yy] = emo_time$US_onset[yy]
      emo_time$duration[yy] <- 1
      emo_time$trial_type[yy] <- 'anticipation'
    }else{
      emo_time$onset[yy] = emo_time$US_onset[yy]
      emo_time$duration[yy] <- 3
      emo_time$trial_type[yy] <- 'US'
    }
  }
  
  emo_time$onset[emo_time$trial_type=='information'] <- as.numeric(emo_time$onset[emo_time$trial_type=='CS'])+1
  emo_time$onset[emo_time$trial_type=='anticipation'] <- as.numeric(emo_time$onset[emo_time$trial_type=='decision'])+2
  emo_time$onset <- as.numeric(emo_time$onset)
  
  #adjust for 10s disdaq delay
  emo_time$onset <- as.numeric(emo_time$onset)+10
  emo_time$duration[emo_time$trial_type=='information'] <- as.numeric(emo_time$onset[emo_time$trial_type=='decision']) - as.numeric(emo_time$onset[emo_time$trial_type=='information'])
  emo_time$duration[emo_time$trial_type=='anticipation'] <- emo_time$onset[emo_time$trial_type=='US'] - emo_time$onset[emo_time$trial_type=='decision']
  emo_time$duration <- as.numeric(emo_time$duration)
  
  #only preserve RT that corresponds to 
  emo_time$RT[emo_time$trial_type!='decision']<-NaN
  emo_time$CS_onset[emo_time$trial_type!='CS']<-NaN
  emo_time$decision_onset[emo_time$trial_type!='decision']<-NaN
    
  #change col from numeric value to text 
  emo_time$participant_made_choice[emo_time$participant_made_choice == "         1"] = "participant"
  emo_time$participant_made_choice[emo_time$participant_made_choice == "         0"] = "computer"
  emo_time$screen_side_choice[emo_time$screen_side_choice == "         1"] = "left"
  emo_time$screen_side_choice[emo_time$screen_side_choice == "         2"] = "right"
  emo_time$US_reinforcement[emo_time$US_reinforcement == "         1"] = "negative"
  emo_time$US_reinforcement[emo_time$US_reinforcement == "         0"] = "neutral"
  
  #create cols with concatenated names
  emo_time$US_trialType <- NaN
  emo_time$US_trialType[emo_time$US_reinforcement == "negative" & emo_time$trial_type == "US"] <- "negative"
  emo_time$US_trialType[emo_time$US_reinforcement == "neutral" & emo_time$trial_type == "US"]  <- "neutral"
  emo_time$CS_trialType <- NaN
  emo_time$CS_trialType[emo_time$US_reinforcement == "negative" & emo_time$trial_type == "CS"] <- "CS+"
  emo_time$CS_trialType[emo_time$US_reinforcement == "neutral" & emo_time$trial_type == "CS"]  <- "CS-"

  #read PE files
  pe.dirs <- list.files('/Users/chendanlei/Dropbox (Partners HealthCare)/U01/EmotionAvoidanceTask/PE_files/', recursive = FALSE)
  subj.pe.dir <- pe.dirs[which (str_sub(subjID,-3,-1) == str_sub(pe.dirs, -7,-5))]
  pe_value <- read.csv(file = paste0('/Users/chendanlei/Dropbox (Partners HealthCare)/U01/EmotionAvoidanceTask/PE_files/', subj.pe.dir), header=FALSE)
  emo_time$PE <-NaN
  emo_time$PE[emo_time$trial_type=='US'] <- pe_value$V1
  
  #change the order of the columns (move the last three cols to first)
  emo_time <- emo_time[,c(which(colnames(emo_time)=="onset"),which(colnames(emo_time)=="duration"),which(colnames(emo_time)=="trial_type"), which(colnames(emo_time)=="US_trialType"), which(colnames(emo_time)=="CS_trialType"), which(colnames(emo_time)=="PE"), which(colnames(emo_time)!="onset" & colnames(emo_time)!="duration" & colnames(emo_time)!="trial_type" & colnames(emo_time)!="CS_trialType" & colnames(emo_time)!="US_trialType" & colnames(emo_time)!="PE") )]
  
  #save the file for each run
  for (zz in 1:5) {
    emo_time_run <- emo_time[emo_time$run_num==zz,]

    if (pain_or_emotion == 'emotion'){
      #save the file
      if (is.element(TRUE,grepl(str_sub(subjID, -2,-1),emo_subj))) {
        dir.create(paste0(output.dir, '/', subjID))
        write.table(emo_time_run, file=paste0(output.dir, '/', subjID, '/', subjID, '_task-emo3_run-0',zz,'_events.tsv'), quote=FALSE,
                    sep='\t', row.names=FALSE)
      }
    }
    
    if (pain_or_emotion == 'pain'){
      if (is.element(TRUE,grepl(str_sub(subjID, -2,-1),pain_subj))) {
        dir.create(paste0(output.dir, '/', subjID))
        write.table(emo_time_run, file=paste0(output.dir, '/', subjID, '/', subjID, '_task-pain3_run-0',zz,'_events.tsv'), quote=FALSE,
                    sep='\t', row.names=FALSE)
      }
    }    
  }
  
}





