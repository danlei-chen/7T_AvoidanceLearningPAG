#!/bin/tcsh
setenv DATA /autofs/cluster/iaslab/FSMAP/FSMAP_data
setenv SCRIPTPATH /autofs/cluster/iaslab/users/danlei/FSMAP/scripts
setenv IMAGE /autofs/cluster/iaslab/users/jtheriault/singularity_images/jtnipyutil/jtnipyutil-2019-01-03-4cecb89cb1d9.simg
setenv PROJNAME painAvd_modeledPE
setenv SINGULARITY /usr/bin/singularity
# input from command line, see example_lvl2_model
setenv FWHM $1

mkdir -p /scratch/$USER/$PROJNAME/wrkdir/
mkdir /scratch/$USER/$PROJNAME/data
mkdir -p /scratch/$USER/$PROJNAME/output
mkdir $DATA/BIDS_modeled/$PROJNAME/lvl2

rsync -ra $DATA/BIDS_modeled/$PROJNAME/* /scratch/$USER/$PROJNAME/data/

rsync $SCRIPTPATH/model/{painAvd_lvl2_model.py,painAvd_lvl2_model_startup.sh} /scratch/$USER/$PROJNAME/wrkdir/
chmod +x /scratch/$USER/$PROJNAME/wrkdir/painAvd_lvl2_model_startup.sh
cd /scratch/$USER
mkdir $DATA/BIDS_modeled/$PROJNAME

$SINGULARITY shell  \
--bind "/scratch/$USER/$PROJNAME/data:/scratch/data" \
--bind "/scratch/$USER/$PROJNAME/output:/scratch/output" \
--bind "/scratch/$USER/$PROJNAME/wrkdir:/scratch/wrkdir" \
--bind "$HOME/license:/license" \
$IMAGE \
/scratch/wrkdir/painAvd_lvl2_model_startup.sh

mkdir -p $DATA/$PROJNAME/lvl2
rsync -r /scratch/$USER/$PROJNAME/output/* $DATA/BIDS_modeled/$PROJNAME/lvl2
rm -r /scratch/$USER/$PROJNAME/
exit

# I was running into a problem because of the tcsh shell on the MGH cluster.
# Getting this error after running $SINGULARITY shell $IMAGE:
#
# Singularity: Invoking an interactive shell within container...
# ERROR: Shell does not exist in container: /usr/local/bin/tcsh
# ERROR: Using /bin/sh instead...
#
# Solution was to create a startup shell script, start_mdl-smooth-prewhite.#!/bin/sh
# This runs :
# /neurodocker/startup.sh \
# python /scratch/wrkdir/mdl_smooth-prewhite.py $SUBJ

# The \ after /neurodocker/startup.sh is necessary, as the python command runs inside a new image invoked.
# The neurodocker/startup.sh command activates the python environment necessary to run all the installed packages.

# This will be important for using the Singularity build in the future.


