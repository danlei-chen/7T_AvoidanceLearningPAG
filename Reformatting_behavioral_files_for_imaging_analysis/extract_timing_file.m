cd ('/Users/chendanlei/Dropbox (Partners Healthcare)/U01/EmotionAvoidanceTask/BIDS_BehavioralData/' )

files=dir('sub*');
files={files.name};

for xx = 1: length(files)
    subj_id=files{xx};
    cd(['/Users/chendanlei/Dropbox (Partners Healthcare)/U01/EmotionAvoidanceTask/BIDS_BehavioralData/',subj_id])
    disp(subj_id)
    
    for yy = 1: 5
        results_table= readtable([subj_id,'_task-emotion_run-0',num2str(yy),'_events.csv']);

        output_file = results_table.onset(find(results_table.reinforced==1 & results_table.run_num==yy & strcmp(results_table.trial_type, 'CS')));%onset
        output_file = [output_file, results_table.duration(find(results_table.reinforced==1 & results_table.run_num==yy & strcmp(results_table.trial_type, 'CS')))];%onset
        output_file = [output_file, repmat(1,size(output_file,1),1)];%weight
        % save('output_file.txt', 'output_file','-ascii','-double')
        dlmwrite([subj_id,'_neg_run',num2str(yy),'.txt'],output_file,' ')

        output_file = results_table.onset(find(results_table.reinforced==0 & results_table.run_num==yy & strcmp(results_table.trial_type, 'CS')));%onset
        output_file = [output_file, results_table.duration(find(results_table.reinforced==0 & results_table.run_num==yy & strcmp(results_table.trial_type, 'CS')))];%onset
        output_file = [output_file, repmat(1,size(output_file,1),1)];%weight
        % save('output_file.txt', 'output_file','-ascii','-double')
        dlmwrite([subj_id,'_neu_run',num2str(yy),'.txt'],output_file,' ')
    end
end



