#!/bin/tcsh
setenv DATA /autofs/cluster/iaslab/FSMAP/FSMAP_data
setenv SCRIPTPATH /autofs/cluster/iaslab/users/danlei/FSMAP/scripts
setenv IMAGE /autofs/cluster/iaslab/users/jtheriault/singularity_images/jtnipyutil/jtnipyutil-2019-01-03-4cecb89cb1d9.simg
setenv PROJNAME painAvd_modeledPE
setenv SINGULARITY /usr/bin/singularity
setenv SUBJ sub-$1

mkdir -p /scratch/$USER/$SUBJ/$PROJNAME/BIDS_preproc/$SUBJ/anat
mkdir -p /scratch/$USER/$SUBJ/$PROJNAME/BIDS_preproc/$SUBJ/func
mkdir /scratch/$USER/$SUBJ/$PROJNAME/wrkdir/
mkdir -p /scratch/$USER/$SUBJ/$PROJNAME/BIDS_modeled

rsync -ra $DATA/BIDS_fmriprep/fmriprep/ses-02/$SUBJ/func/*pain3_run-* /scratch/$USER/$SUBJ/$PROJNAME/BIDS_preproc/$SUBJ/func
rsync -ra $DATA/BIDS_fmriprep/fmriprep/ses-02/$SUBJ/anat/sub-*_T1w_space-MNI* /scratch/$USER/$SUBJ/$PROJNAME/BIDS_preproc/$SUBJ/anat

rsync $SCRIPTPATH/model/{painAvd_lvl1_model.py,painAvd_lvl1_model_startup.sh} /scratch/$USER/$SUBJ/$PROJNAME/wrkdir/
chmod +x /scratch/$USER/$SUBJ/$PROJNAME/wrkdir/painAvd_lvl1_model_startup.sh
cd /scratch/$USER
mkdir $DATA/BIDS_modeled/$PROJNAME

$SINGULARITY exec  \
--bind "/scratch/$USER/$SUBJ/$PROJNAME/BIDS_preproc:/scratch/data" \
--bind "/scratch/$USER/$SUBJ/$PROJNAME/BIDS_modeled:/scratch/output" \
--bind "/scratch/$USER/$SUBJ/$PROJNAME/wrkdir:/scratch/wrkdir" \
--bind "$HOME/license:/license" \
$IMAGE \
/scratch/wrkdir/painAvd_lvl1_model_startup.sh

rsync -r /scratch/$USER/$SUBJ/$PROJNAME/BIDS_modeled/ $DATA/BIDS_modeled/
rm -r /scratch/$USER/$SUBJ/$PROJNAME/
exit