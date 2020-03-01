%% subject-level plots
% emotion
emo_s = [14,15,16,22,23,28,30,34,37,39,43,45,50,53,54,57,60,61,66,68,69,71,73,74,81,83,86,92,94];
%problem: all after 94
% pain
pain_s = [18,19,20,24,25,26,31,32,33,41,47,48,49,52,55,56,58,59,62,64,65,67,72,80,88,90,95,98];
%problem: 70,82,84,85,91
emoAndPain_s = [emo_s,pain_s];
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
cs=0;clear OUT output;
logistic_regression_mtx_all = []; %switch(0/1),trials,reinforced(i-lag),subj
model_fit = [];
for s = pain_s
    disp(['subj:', num2str(s)]);
    
    cs=cs+1; 
    [OUT(cs,:), output(cs), logistic_regression_mtx, negloglik]=Emotion_behavioral_analysis_individual(s); 
    logistic_regression_mtx_all = [logistic_regression_mtx_all;logistic_regression_mtx];
    model_fit = [model_fit; negloglik];
end
if s == emo_s(end)
%     save model_fit_PE1_Q1_nogemma_emo.mat model_fit
   save logit_mtx_emo.mat logistic_regression_mtx_all
else
%     save model_fit_PE1_Q1_nogemma_pain.mat model_fit
   save logit_mtx_pain.mat logistic_regression_mtx_all
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
cs=0;clear OUT output;
logistic_regression_mtx_all = []; %switch(0/1),trials,reinforced(i-lag),subj
model_fit = [];
for s = pain_s
    disp(['subj:', num2str(s)]);
    
    cs=cs+1; 
    [OUT(cs,:), output(cs), logistic_regression_mtx, negloglik]=Emotion_behavioral_analysis_individual(s); 
    logistic_regression_mtx_all = [logistic_regression_mtx_all;logistic_regression_mtx];
    model_fit = [model_fit; negloglik];
end
if s == emo_s(end)
%     save model_fit_PE1_Q1_nogemma_emo.mat model_fit
   save logit_mtx_emo.mat logistic_regression_mtx_all
else
%     save model_fit_PE1_Q1_nogemma_pain.mat model_fit
   save logit_mtx_pain.mat logistic_regression_mtx_all
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Y=OUT;

Routput = reshape(Y,[1,size(Y,1)*size(Y,2)]);
save pain.mat Routput

save logit_mtx.mat logistic_regression_mtx_all

%% group plots
figure();
barplot_columns([Y(:,1),Y(:,2),Y(:,3),Y(:,4)],'dolines');
% figure();
% group_mean = mean([Y(:,1),Y(:,2),Y(:,3),Y(:,4)]);
% bar(1:4,group_mean,'FaceColor',[0.35 0.65 0.93])  
% % hold on
% % scatter_x = [repmat(1,length(Y(:,1)),1);repmat(2,length(Y(:,2)),1);repmat(3,length(Y(:,3)),1);repmat(4,length(Y(:,4)),1);]
% % scatter_y = [Y(:,1);Y(:,2);Y(:,3);Y(:,4)];
% % gscatter(scatter_x,scatter_y,scatter_x,[0.5 0.85 1],'o')
% hold on
% x = plot([Y(:,1),Y(:,2),Y(:,3),Y(:,4)]','-co');
% x.Color(4)=0.3;
% hold on
% errhigh = std([Y(:,1),Y(:,2),Y(:,3),Y(:,4)])/sqrt(size([Y(:,1),Y(:,2),Y(:,3),Y(:,4)],1));
% errlow = std([Y(:,1),Y(:,2),Y(:,3),Y(:,4)])/sqrt(size([Y(:,1),Y(:,2),Y(:,3),Y(:,4)],1));
% er = errorbar(1:4,group_mean,errlow,errhigh);    
% er.Color = [0 0 0];                            
% er.LineStyle = 'none';  
% er.LineWidth = 1;  
hold off
set(gca,'XTickLabels',{'CS+Acq' 'CS-Acq' 'CS+Test' 'CS-Test'});
ylabel 'Expectancy Rating'
xlabel 'Condition'
title 'Learning Effects'
set(gca,'XTickLabelRotation',60)
legend('off')
drawnow; snapnow;
%rm_anova2
X=[Y(:,1);Y(:,2);Y(:,3);Y(:,4)];
S=repmat(1:cs,1,4)';
F1=[repmat("CS+",1,cs)';repmat("CS-",1,cs)';repmat("CS+",1,cs)';repmat("CS-",1,cs)'];
F2=[repmat("Acq",1,cs)';repmat("Acq",1,cs)';repmat("Test",1,cs)';repmat("Test",1,cs)'];
FACTNAMES = {'Conditioning', 'Tasks'};
rm_anova2(X,S,F1,F2,FACTNAMES) 

figure();
barplot_columns([Y(:,5),Y(:,6),Y(:,7),Y(:,8)],'dolines');
set(gca,'XTickLabels',{'CS+ Reinforced' 'CS+ Not Reinforced' 'CS- Reinforced' 'CS- Not Reinforced' });
ylabel 'Unpleasantness Rating'
title 'Test Phase'
set(gca,'XTickLabelRotation',90)
drawnow; snapnow;
%rm_anova2
X=[Y(:,5);Y(:,6);Y(:,7);Y(:,8)];
S=repmat(1:cs,1,4)';
F1=[repmat("CS+",1,cs)';repmat("CS+",1,cs)';repmat("CS-",1,cs)';repmat("CS-",1,cs)'];
F2=[repmat("Reinforced",1,cs)';repmat("Unreinforced",1,cs)';repmat("Reinforced",1,cs)';repmat("Unreinforced",1,cs)'];
FACTNAMES = {'Conditioning', 'Reinforcement'};
rm_anova2(X,S,F1,F2,FACTNAMES) 

% clf;
figure();
errorbar([1:6],mean(Y(:,9:14)),std([Y(:,9:14)])/sqrt(size([Y(:,9:14)],1)),'r-o','LineWidth',2)
hold on
errorbar([1:6],mean(Y(:,15:20)),std([Y(:,15:20)])/sqrt(size([Y(:,15:20)],1)),'b-.o','LineWidth',2)
% lineplot_columns([Y(:,9:14)],'linestyle','-','color',[1 0 0])
% lineplot_columns([Y(:,15:20)],'linestyle','-.','color',[0 0 1])
set(gca,'XTick',1:6);
xlabel 'Trials Since Reinforcement'
ylabel 'Probability Switch'
title 'Avoidance Learning'
ha=findobj(gca,'type','line');
legend(ha,{'CS-','CS+'})
drawnow; snapnow;

figure();
CSminusMeanLog=Y(:,9:14);
[r,c]=find(ismember(CSminusMeanLog,-Inf));
CSminusMeanLog(r,:)=[];
CSplusMeanLog=Y(:,15:20);
[r,c]=find(ismember(CSplusMeanLog,-Inf));
CSplusMeanLog(r,:)=[];
errorbar([1:6],mean(CSminusMeanLog),std(CSminusMeanLog)/sqrt(size(CSminusMeanLog,1)),'ro','LineWidth',2)
hold on
errorbar([1:6],mean(CSplusMeanLog),std(CSplusMeanLog)/sqrt(size(CSplusMeanLog,1)),'bo','LineWidth',2)
p = polyfit([1:6],mean(CSminusMeanLog),2);
f = polyval(p,linspace(1,6,40));
plot(linspace(1,6,40),f,'r-','LineWidth',2)
p = polyfit([1:6],mean(CSplusMeanLog),2);
f = polyval(p,linspace(1,6,40));
plot(linspace(1,6,40),f,'b-.','LineWidth',2)
set(gca,'XTick',1:6);
xlabel 'Trials Since Reinforcement'
ylabel 'Probability Switch'
title 'Avoidance Learning'
ha=findobj(gca,'type','line');
legend(ha,{'CS-','CS+'})
drawnow; snapnow;
