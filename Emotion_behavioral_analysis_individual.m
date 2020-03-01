function [OUT, output, logistic_regression_mtx,negloglik] = Emotion_behavioral_analysis_individual(s)
    addpath('/Users/chendanlei/Google Drive/U01/EmotionAvoidanceTask/behavioral analysis/QLearning')
    
%     data_dir = '/Users/chendanlei/Google Drive/U01/EmotionAvoidanceTask/behavioral analysis/phil scripts hybrid_conditioning/BehavioralData';
    data_dir = '/Users/chendanlei/Dropbox (Partners HealthCare)/NCI_U01_Shared_Data/BehavioralData';
    task_dir = '/Users/chendanlei/Google Drive/U01/EmotionAvoidanceTask/behavioral analysis/hybrid_conditioning';
    save_pe_dir = '/Users/chendanlei/Dropbox (Partners HealthCare)/U01/EmotionAvoidanceTask/PE_files/';
    save_fig_dir = '/Users/chendanlei/Google Drive/U01/EmotionAvoidanceTask/behavioral analysis/fig/';

    %% acquisition (before scanning)

    acquisition_file=dir(sprintf('%s/FSMAP_%03g/*acquisition_*',data_dir,s));
    acquisition_file = acquisition_file(~contains({acquisition_file.name}, 'original'));
    acquisition_data=importdata([acquisition_file.folder '/' acquisition_file.name]);
    dat=acquisition_data.data;
    dat=dat(~isnan(dat(:,1)),:);
    acquisition_data.colheaders = [{'stim_num'},{'CS (1=reinforced, 2=unreinforced)'},{'US (1=negative, 0=neutrla)'},{'expectancy rating'},{'CS onset'},{'RT'}];

    %CS+ denotes reinforced trialsCS- means unreinforced trial
    %tstat of CS+ and CS- expectancy
    expectancy_CSplus_acq=[nanmean(dat(dat(:,2)==1,4)) nanstd(dat(dat(:,2)==1,4))];
    expectancy_CSminus_acq=[nanmean(dat(dat(:,2)==2,4)) nanstd(dat(dat(:,2)==2,4))];
    [h , p, ci, st_acq]=ttest2(dat(dat(:,2)==1,4),dat(dat(:,2)==2,4));
    t_difference_exp_acq=st_acq.tstat;

    %combining CS+ and CS- trial ratings
    X=[dat(dat(:,2)==1,4),dat(dat(:,2)==2,4)];
    %mean of CS+ and CS- ratings in pre-scan acquisition
    OUT(1:2)=nanmean(X);

    figure(1);clf
    subplot(3,3,1);hold on;
    bar(nanmean(X),'FaceColor',[.7 .7 .7]);  errorbar(nanmean(X),nanstd(X)/sqrt(size(X,1)),'linestyle','none','color',[0 0 0]);
    set(gca,'XTickLabelRotation',45)
    set(gca,'XTick',1:2)
    set(gca,'XTickLabels',{'CS+' 'CS-'});
    ylabel 'Expectancy Rating'
    title 'Acquisition Phase'

    %% test scan (first scan)

    test_file=dir(sprintf('%s/FSMAP_%03g/*task_test*',data_dir,s));
    test_file = test_file(~contains({test_file.name}, 'original'));
    dat=import_test_file([test_file.folder '/' test_file.name]);
    dat=dat(~isnan(dat(:,1)),:);
    header = [{'Stimulus_Nr'},{'CS (1=reinforced during acquisition, 2=unreinforced)'},{'US (1=negative, 0=neutral)'},{'Rating index (1=CS expectancy rating, 0=US rating)'},{'Rating (1=button press, 0=no answer)'},{'Onset'},{'RT'},{'Image'}];

    % compare expectancy rating for CS+andCS- --> dat(:,4)==1
    expectancy_CSplus_test=[nanmean(dat(dat(:,4)==1 &dat(:,2)==1,5)) nanstd(dat(dat(:,4)==1 &dat(:,2)==1,5))];
    expectancy_CSminus_test=[nanmean(dat(dat(:,4)==1 &dat(:,2)==2,5)) nanstd(dat(dat(:,4)==1 &dat(:,2)==2,5))];
    [h, p, ci, st_test]=ttest2(dat(dat(:,4)==1 &dat(:,2)==1,5),dat(dat(:,4)==1 &dat(:,2)==2,5));
    t_difference_exp_test=st_test.tstat;

    X=[dat(dat(:,4)==1 &dat(:,2)==1,5),dat(dat(:,4)==1 &dat(:,2)==2,5)];
    %mean of CS+/- expectancy rating in testing
    OUT(3:4)=nanmean(X);

    subplot(3,3,2);hold on;
    bar(nanmean(X),'FaceColor',[.7 .7 .7]);  errorbar(nanmean(X),nanstd(X)/sqrt(size(X,1)),'linestyle','none','color',[0 0 0]);
    set(gca,'XTickLabelRotation',45)
    set(gca,'XTick',1:2)
    %     set(gca,'YLim',[0 5]);
    set(gca,'XTickLabels',{'CS+' 'CS-'});
    ylabel 'Expectancy Rating'
    title 'Test Phase'

    % unpleasantness ratings for US in CS+ or CS- trials
    unpleasantness_CSplus_test=[nanmean(dat(dat(:,2)==1,5)) nanstd(dat(dat(:,2)==1,5))];
    unpleasantness_CSminus_test=[nanmean(dat(dat(:,2)==2,5)) nanstd(dat(dat(:,2)==2,5))];
    [h p ci st_test]=ttest2(dat(dat(:,2)==1,5),dat(dat(:,2)==2,5));
    t_difference_unp_test=st_test.tstat;

    X=[dat(dat(:,2)==1 & dat(:,3)==1,5),dat(dat(:,2)==1& dat(:,3)==0,5),dat(dat(:,2)==2& dat(:,3)==1,5),dat(dat(:,2)==2& dat(:,3)==0,5)];
    % unpleasantness rating of: CS+ with negative outcome, CS+ with neutral outcome, CS- with negative
    % outcome, and CS- with neutral outcome
    OUT(5:8)=nanmean(X);

    subplot(3,3,3);hold on;
    bar(nanmean(X),'FaceColor',[.7 .7 .7]); errorbar(nanmean(X),nanstd(X)/sqrt(size(X,1)),'linestyle','none','color',[0 0 0]);
    set(gca,'XTickLabelRotation',45)
    %     set(gca,'YLim',[0 5]);
    set(gca,'XTick',1:4);
    set(gca,'XTickLabels',{'CS+ R' 'CS+ NR' 'CS- R' 'CS- NR' });
    ylabel 'Unpleasantness Rating'
    title 'Test Phase'

    %% avoidance scan (5 scans)

    avoidance_file=dir(sprintf('%s/FSMAP_%03g/*task_avoidance*',data_dir,s));
    avoidance_file = avoidance_file(~contains({avoidance_file.name}, 'original'));
    dat=import_avoidance_file([avoidance_file.folder '/' avoidance_file.name]);
    dat=dat(~isnan(dat(:,1)),:);
    header = ['stim_num','participant_made_choice (1=ppt, 0=computer)','CS_stim_order_on_screen (either circle is on the left or right)','CS_onset','decision_onset','screen_side_choice','RT','US_reinforcement (1=negative, 0=neutral)','choice','image','US_onset'];

    %The randomWalk file is X
    load([task_dir,'/RandomWalk', num2str(rem(s,4)+1), '.mat'])
    randomWalk=X;

    Reinforced=dat(:,8); %reinforced
    Active=dat(:,2); %active trial
    Circle=dat(:,9); %chose circle
    dat = [Reinforced,Active,Circle];
    save s23dat.mat dat
    
    %plot behavior over time
    subplot(3,3,7:9); hold on;
    nt=length(Circle);
    %X is from unpleasant ratings of test scan: blue: CS + with negative outcome, red: CS+ with neutral outcome
    h1=plot(1:nt,randomWalk(1:nt,1),'color',[0 0 1],'Linewidth',2);
    h2=plot(1:nt,randomWalk(1:nt,2),'color',[1 0 0],'Linewidth',2);
    %chose circle
    chooseCircle = double(Circle==1);chooseCircle(chooseCircle==0)=nan;
    h3=plot(1:nt,5*chooseCircle,'o','markersize',4,'color',[0 0 1],'markeredgecolor',[0 0 1],'markerfacecolor',[0 0 1]);
    %chose triangle
    chooseTriangle = double(~Circle==1);chooseTriangle(chooseTriangle==0)=nan;
    h4=plot(1:nt,5*chooseTriangle,'^','markersize',4,'color',[1 0 0],'markerfacecolor',[1 0 0],'markeredgecolor',[1 0 0]);
    %active
    activeTrial = double(Active==1);activeTrial(activeTrial==0)=nan;
    h5=plot(1:nt,2*activeTrial,'.','markersize',5,'color',[0 0 0],'markeredgecolor',[0 0 0],'markerfacecolor',[0 0 0]);
    % reinforced trial
    reinforcedTrial = double(Reinforced==1);
    reinforcedTrial(~reinforcedTrial) = NaN;
    h6=plot(1:nt,10*reinforcedTrial,'square','markersize',4,'color',[0 0 0],'markerfacecolor',[0 0 0]);
    set(gca,'YLim',[0 100])
    xlabel Trial
    ylabel P(Reinforcement)
    legend([h1(1) h2(1) h3(1) h4(1) h5(1) h6(1)],'P(Reinf): Circle','P(Reinf): Triangle','Chose Circle','Chose Triangle','Active Trial','Reinforced Trial')
    title(['Subject: ' num2str(s) '     Active Reinforcement = ' sprintf('%1.2f',100*nanmean(Reinforced(Active==1))) '%'  '     Passive Reinforcement = ' sprintf('%1.2f',100*nanmean(Reinforced(Active==0))) '%'])
%     % ppt chose circle
%     pptCircle = double(Circle & Active==1);
%     pptCircle(~pptCircle) = NaN;
%     plot(1:nt,5*pptCircle,'o','markersize',4,'color',[0 0 1],'markeredgecolor',[0 0 1],'markerfacecolor',[0 0 1]);
%     % ppt chose triangle
%     pptTriangle = double(~Circle & Active==1);
%     pptTriangle(~pptTriangle) = NaN;
%     plot(1:nt,5*pptTriangle,'^','markersize',4,'color',[1 0 0],'markerfacecolor',[1 0 0],'markeredgecolor',[1 0 0]);
% %     text(0,15,'participant choice')
%     % computer chose circle
%     cmpCircle = double(Circle & Active==0);
%     cmpCircle(~cmpCircle) = NaN;    
%     plot(1:nt,0*cmpCircle,'o','markersize',4,'color',[0 0 1],'markeredgecolor',[0 0 1],'markerfacecolor',[0 0 1]);
%     % computer chose triangle
%     cmpTriangle = double(~Circle & Active==0);
%     cmpTriangle(~cmpTriangle) = NaN;  
%     plot(1:nt,0*cmpTriangle,'^','markersize',4,'color',[1 0 0],'markerfacecolor',[1 0 0],'markeredgecolor',[1 0 0]);
% %     text(0,5,'computer choice')

    %%
    resp = double(Circle)+1; %chose circle = 1, triangle = 2
    curdat=[Reinforced, resp, Active];
    curdat=curdat(~isnan(curdat(:,1)),:);

    output=QLearning_PAL(curdat);
    
    %add back no response trials
    PE_mtx = Reinforced;
    PE_mtx(~isnan(PE_mtx)) = output.PE';
    if numel(num2str(s)) ==2 
        subnum = strcat('0',num2str(s));
    elseif numel(num2str(s)) ==3
        subnum = num2str(s);
    end
    writematrix(PE_mtx,strcat(save_pe_dir,'PE_mtx_',subnum,'.csv'))  
    
    negloglik = output.negloglik;

%     logistic_regression_mtx_CSplus = []; %switch(0/1),reinforced(i-lag),trials,subj
%     logistic_regression_mtx_CSminus = []; %switch(0/1),reinforced(i-lag),trials,subj
    logistic_regression_mtx = [];  %switch(0/1),reinforced(i-lag),trials,subj
    %lag: looking at the last 6 trials
    for lag=1:6
        clear switch_reinforced_circle switch_reinforced_triangle
        for i=(1+lag):nt
            if Active(i)==1
                switch_reinforced_circle(i-lag)=Reinforced(i-lag)==1 & Circle(i) ~= Circle(i-lag) & Circle(i)==0; %previous trial was reinforced, switched, and this trial is a circle
                switch_reinforced_triangle(i-lag)=Reinforced(i-lag)==1 & Circle(i) ~= Circle(i-lag)  & Circle(i)==1; %previous trial was reinforced, switched, and this trial is a triangle
                switch_reinforced(i-lag)=Reinforced(i-lag)==1 & Circle(i) ~= Circle(i-lag);

                reinforced_circle(i-lag)=Reinforced(i-lag)==1 & Circle(i-lag)==1; %previous trial was reinforced and was a triangle
                reinforced_triangle(i-lag)=Reinforced(i-lag)==1 & Circle(i-lag)==0; %previous trial was reinforced and was a circle
                reinforced(i-lag)=Reinforced(i-lag)==1;
                
%                 if rem(s,2)==1 %if circle is CS+
%                     logistic_regression_mtx = [logistic_regression_mtx; [switch_reinforced_circle(i-lag),lag,reinforced_circle(i-lag),s]];
%                     logistic_regression_mtx = [logistic_regression_mtx; [switch_reinforced_triangle(i-lag),lag,reinforced_triangle(i-lag),s]];
%                 elseif rem(s,2)~=1 %if triangle is CS+
%                     logistic_regression_mtx = [logistic_regression_mtx; [switch_reinforced_circle(i-lag),lag,reinforced_circle(i-lag),s]];
%                     logistic_regression_mtx = [logistic_regression_mtx; [switch_reinforced_triangle(i-lag),lag,reinforced_triangle(i-lag),s]];
%                 end
                
            end
        end
        
        %OUT column 9-14: CS+
        %OUT column 15-20: CS-
        if rem(s,2)==1 %if circle is CS+
            OUT(8+lag)=sum(switch_reinforced_circle)/sum(reinforced_circle); % switch after reinforcing circle CS+
            OUT(14+lag)=sum(switch_reinforced_triangle)/sum(reinforced_triangle); % switch after reinforcing triangle CS-
            while length(switch_reinforced_triangle) ~= length(reinforced_triangle)
                switch_reinforced_triangle(end+1)=0;
            end
            while length(switch_reinforced_circle) ~= length(reinforced_circle)
                switch_reinforced_circle(end+1)=0;
            end
            logistic_regression_mtx = [logistic_regression_mtx; [switch_reinforced_circle(reinforced_circle==1)',repmat(1,[length(switch_reinforced_circle(reinforced_circle==1)),1]),repmat(lag,[length(switch_reinforced_circle(reinforced_circle==1)),1]),repmat(s,[length(switch_reinforced_circle(reinforced_circle==1)),1])]];
            logistic_regression_mtx = [logistic_regression_mtx; [switch_reinforced_triangle(reinforced_triangle==1)',repmat(0,[length(switch_reinforced_triangle(reinforced_triangle==1)),1]),repmat(lag,[length(switch_reinforced_triangle(reinforced_triangle==1)),1]),repmat(s,[length(switch_reinforced_triangle(reinforced_triangle==1)),1])]];
        else
            OUT(8+lag)=sum(switch_reinforced_triangle)/sum(reinforced_triangle); % switch after reinforcing triangle CS+
            OUT(14+lag)=sum(switch_reinforced_circle)/sum(reinforced_circle); % switch after reinforcing circle CS-
            while length(switch_reinforced_triangle) ~= length(reinforced_triangle)
                switch_reinforced_triangle(end+1)=0;
            end
            while length(switch_reinforced_circle) ~= length(reinforced_circle)
                switch_reinforced_circle(end+1)=0;
            end
            logistic_regression_mtx = [logistic_regression_mtx; [switch_reinforced_triangle(reinforced_triangle==1)',repmat(1,[length(switch_reinforced_triangle(reinforced_triangle==1)),1]),repmat(lag,[length(switch_reinforced_triangle(reinforced_triangle==1)),1]),repmat(s,[length(switch_reinforced_triangle(reinforced_triangle==1)),1])]];
            logistic_regression_mtx = [logistic_regression_mtx; [switch_reinforced_circle(reinforced_circle==1)',repmat(0,[length(switch_reinforced_circle(reinforced_circle==1)),1]),repmat(lag,[length(switch_reinforced_circle(reinforced_circle==1)),1]),repmat(s,[length(switch_reinforced_circle(reinforced_circle==1)),1])]];
        end

    %     OUT(20+lag)=sum(switch_reinforced)/sum(reinforced); % switch after reinforcing triangle
    end
    
    subplot(3,3,4:6); hold on;
    h1=plot(1:6,OUT(9:14),'k-.','linewidth',2);
    scatter(1:6,OUT(9:14),50,'k','filled')

    h2=plot(1:6,OUT(15:20),'k--','linewidth',2);
    scatter(1:6,OUT(15:20),50,'k','filled')
    % 
    % h3=plot(1:6,OUT(21:26),'k-','linewidth',2);
    % scatter(1:6,OUT(21:26),50,'k','filled')

    legend([h1 h2],{'CS+','CS-'},'location','northeastoutside')
    set(gca,'XTick',1:6)
    xlabel 'Trials since reinforcement'
    ylabel 'P(Switch)'
    title(['Avoidance Phase: Learning Rate = ',sprintf('%03f',output.alpha),' Softmax = ',sprintf('%03f',output.beta),' Discount Factor = ', sprintf('%03f',output.gamma)])
    set(gcf,'Position',[0 8 8 11],'units','inches');
    set(gcf,'Position',[0 8 8 11],'units','inches');
    drawnow; snapnow;
    
    saveas(figure(1),strcat(save_fig_dir,'fig_subj_',subnum,'.png'))
end


