%% analysis using NPS and PINES on data from a 'pain' study
project = 'painAvd_modeledPE';
copeName = 'cope1.nii.gz';

%set up some paths for matlab
addpath('/Users/chendanlei/Google Drive/U01/EmotionAvoidanceTask/NPS_PINE_validation/NPS_masks/') %where the NPS and PINES are
addpath(genpath('/Users/chendanlei/Documents/GitHub/CanlabCore/')) %core tools from CANLab (file IO and creating fmri data objects)
addpath(genpath('/Users/chendanlei/Documents/GitHub/Neuroimaging_Pattern_Masks')) %other masks
addpath(genpath('/Users/chendanlei/Documents/MATLAB/spm12')) %spm for loading fmri data, and some computations

% organize contrasts or parameter estimates into a single folder 
% cd '/Users/chendanlei/Desktop/U01/emoTest_Exp-NN-PE/smooth/sub-*/model/fwhm_5.0_sub-*/_modelestimate0/cope4.nii.gz'
% scp -r dz609@door.nmr.mgh.harvard.edu:/autofs/cluster/iaslab/FSMAP/FSMAP_data/BIDS_modeled/painAvd_modeledPE/smooth /Volumes/IASL/People/Researchers/Danlei/BIDS_modeled/painAvd_modeledPE
nifti_files=dir(fullfile('/Volumes/IASL/People/Researchers/Danlei/BIDS_modeled/',project,'/smooth/sub-*/model/fwhm_5.0_sub-*/_modelestimate0/',copeName))


%% load data into fmri_data object
data=fmri_data(fullfile({nifti_files(:).folder}, {nifti_files(:).name}));


%% use plot to visualize data first

% plot(data)

%% load NPS into a fmri data object

NPS = fmri_data(which('weights_NSF_grouppred_cvpcr.img'));
% orthviews(NPS)
%% load the PINES into a fmri data object
PINES = fmri_data(which('Rating_Weights_LOSO_2.nii'));
% orthviews(PINES)
%% use apply mask to compute pattern expression

pattern_expression_NPS=apply_mask(data,NPS,'pattern_expression','cosine_similarity');
pattern_expression_PINES=apply_mask(data,PINES,'pattern_expression','cosine_similarity');

%% plot pattern expression

barplot_columns([pattern_expression_NPS,pattern_expression_PINES],'dolines')
xticklabels({'NPS', 'PINES'})

%% other models to look at

% imagenames = {'weights_NSF_grouppred_cvpcr.img' ...     % Wager et al. 2013 NPS   - somatic pain
%     'NPSp_Lopez-Sola_2017_PAIN.img' ...                 % 2017 Lopez-Sola positive NPS regions only
%     'NPSn_Lopez-Sola_2017_PAIN.img' ...                 % 2017 Lopez-Sola negative NPS regions only, excluding visual
%     'nonnoc_v11_4_137subjmap_weighted_mean.nii' ...     % Woo 2017 SIIPS - stim-indep pain
%     'Rating_Weights_LOSO_2.nii'  ...                    % Chang 2015 PINES - neg emo
%     'dpsp_rejection_vs_others_weights_final.nii' ...    % Woo 2014 romantic rejection
%     'bmrk4_VPS_unthresholded.nii' ...                   % Krishnan 2016 Vicarious pain VPS
%     'Krishnan_2016_VPS_bmrk4_Without_Occipital_Lobe.nii' ... % Krishnan 2016 no occipital
%     'ANS_Eisenbarth_JN_2016_GSR_pattern.img' ...        % Eisenbarth 2016 autonomic - GSR
%     'ANS_Eisenbarth_JN_2016_HR_pattern.img' ...         % Eisenbarth 2016 autonomic - heart rate (HR)
%     'FM_Multisensory_wholebrain.nii' ...                % 2017 Lopez-Sola fibromyalgia 
%     'FM_pain_wholebrain.nii' ...                        % 2017 Lopez-Sola fibromyalgia 
%     'Ashar_2017_empathic_care_marker.nii' ...           % 2017 Ashar et al. Empathic care and distress
%     'Ashar_2017_empathic_distress_marker.nii'};         
