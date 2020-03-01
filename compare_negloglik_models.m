pain_model = [];
load('model_fit_PE2_Q1_gemma_pain.mat')
pain_model=[pain_model,model_fit];
load('model_fit_PE2_Q1_nogemma_pain.mat')
pain_model=[pain_model,model_fit];
load('model_fit_PE2_Q2_gemma_pain.mat')
pain_model=[pain_model,model_fit];
load('model_fit_PE2_Q2_nogemma_pain.mat')
pain_model=[pain_model,model_fit];
load('model_fit_PE1_Q1_gemma_pain.mat')
pain_model=[pain_model,model_fit];
load('model_fit_PE1_Q1_nogemma_pain.mat')
pain_model=[pain_model,model_fit];

barplot_columns(pain_model,'dolines');
set(gca,'XTickLabels',{'2,1,y' '2,1,n' '2,2,y' '2,2,n' '1,1,y' '1,1,n'});
ylabel 'negloglik'
title 'pain'
set(gca,'XTickLabelRotation',90)
drawnow; snapnow;



emo_model = [];
load('model_fit_PE2_Q1_gemma_emo.mat')
emo_model=[emo_model,model_fit];
load('model_fit_PE2_Q1_nogemma_emo.mat')
emo_model=[emo_model,model_fit];
load('model_fit_PE2_Q2_gemma_emo.mat')
emo_model=[emo_model,model_fit];
load('model_fit_PE2_Q2_nogemma_emo.mat')
emo_model=[emo_model,model_fit];
load('model_fit_PE1_Q1_gemma_emo.mat')
emo_model=[emo_model,model_fit];
load('model_fit_PE1_Q1_nogemma_emo.mat')
emo_model=[emo_model,model_fit];

figure();
barplot_columns(emo_model,'dolines');
set(gca,'XTickLabels',{'2,1,y' '2,1,n' '2,2,y' '2,2,n' '1,1,y' '1,1,n'});
ylabel 'negloglik'
title 'emotion'
set(gca,'XTickLabelRotation',90)
drawnow; snapnow;

