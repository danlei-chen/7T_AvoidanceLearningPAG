def create_lvl2tfce_wf(mask=False):
    '''
    Input [Mandatory]:
        ~~~~~~~~~~~ Set through inputs.inputspec
        proj_name: String, naming subdirectory to use to identify this instance of lvl2 modeling.
            e.g. 'nosmooth'
            The string will be used as a subdirectory in output_dir.
        copes_template: String, naming full path to the cope files. Use wildcards to grab all cope files wanted.
            contrast (below) will be used iteratively to grab only the appropriate con files from this glob list on each iteration.
            e.g. inputs.inputspec.copes_template = '/home/neuro/workdir/stress_lvl2/data/nosmooth/sub-*/model/sub-*/_modelestimate0/cope*nii.gz'
        contrast: Character defining contrast name.
            Name should match a dictionary entry in full_cons and con_regressors.
            ** Often you will want to input this with an iterable node.
        full_cons: dictionary of each contrast.
            Names should match con_regressors.
            Entries in format [('name', 'stat', [condition_list], [weight])]
            e.g. full_cons = {
                '1_instructions_Instructions': [('1_instructions_Instructions', 'T', ['1_instructions_Instructions'], [1])]
                }
        output_dir: string, representing directory of output.
            e.g. inputs.inputspec.output_dir ='/home/neuro/output'
            In the output directory, the data will be stored in a root dir, giving the time and date of processing.
            If a mask is used, the mask will also be included in the output folder name. wholebrain is used otherwise.
        subject_list: list of string, with BIDs-format IDs to identify subjects.
            Use this to drop high movement subjects, even if they are among other files that will be grabbed.
            e.g. inputs.inputspec.subject_list =['sub-001', sub-002']
        con_regressors: dictionary of by-subject regressors for each contrast.
                Names should match full_cons.
                e.g. inputs.inputspec.con_regressors = {
                        '1_instructions_Instructions': {'1_instructions_Instructions': [1] * len(subject_list),
                        'reg2': [0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1],
                        'reg3': [1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0],
                        }
                    }
        Input [Optional]:
            mask: [default: False] path to mask file. Can have different dimensions from functional data, but should obviously be in the same reference space if anatomical (see jt_util.align_mask).
                e.g. inputs.inputspec.mask_file = '/home/neuro/atlases/FSMAP/stress/realigned_masks/amygdala_bl_flirt.nii.gz'
            sinker_subs: list of tuples, each containing a pair of strings.
                These will be sinker substitutions. They will change filenames in the output folder.
                Usually best to run the pipeline once, before deciding on these.
                e.g. inputs.inputspec.sinker_subs = [('tstat', 'raw_tstat'),
                       ('tfce_corrp_raw_tstat', 'tfce_corrected_p')]
        Output:
            lvl2tfce_wf: workflow to perform second-level modeling, using threshold free cluster estimation (tfce; see https://fsl.fmrib.ox.ac.uk/fsl/fslwiki/Randomise/UserGuide)
    '''
    import nipype.pipeline.engine as pe # pypeline engine
    import nipype.interfaces.fsl as fsl
    import os
    from nipype import IdentityInterface
    from nipype.interfaces.utility.wrappers import Function
    ##################  Setup workflow.
    lvl2tfce_wf = pe.Workflow(name='lvl2tfce_wf')

    inputspec = pe.Node(IdentityInterface(
        fields=['proj_name',
                'copes_template',
                'output_dir',
                'mask_file',
                'subject_list',
                'con_regressors',
                'full_cons',
                'sinker_subs',
                'contrast'
                ],
        mandatory_inputs=False),
                 name='inputspec')
    if mask:
        inputspec.inputs.mask_file = mask

    ################## Make output directory.
    def mk_outdir(output_dir, proj_name, mask=False):
        import os
        from time import gmtime, strftime
        time_prefix = strftime("%Y-%m-%d_%Hh-%Mm", gmtime())+'_'
        if mask:
            new_out_dir = os.path.join(output_dir, time_prefix + mask.split('/')[-1].split('.')[0])
        else:
            new_out_dir = os.path.join(output_dir, time_prefix + 'wholebrain', proj_name)
        if not os.path.isdir(new_out_dir):
            os.makedirs(new_out_dir)
        return new_out_dir

    make_outdir = pe.Node(Function(input_names=['output_dir', 'proj_name', 'mask'],
                                   output_names=['new_out_dir'],
                                   function=mk_outdir),
                          name='make_outdir')

    ################## Get contrast
    def get_con(contrast, full_cons, con_regressors):
        con_info = full_cons[contrast]
        reg_info = con_regressors[contrast]
        return con_info, reg_info

    get_model_info = pe.Node(Function(input_names=['contrast', 'full_cons', 'con_regressors'],
                                      output_names=['con_info', 'reg_info'],
                                      function=get_con),
                             name='get_model_info')
    # get_model_info.inputs.full_cons = From inputspec
    # get_model_info.inputs.full_regs = From inputspec
    # get_model_info.inputs.contrast = From inputspec

    ################## Get files
    def get_files(subject_list, copes_template, contrast):
        import glob
        temp_list = []
        for x in glob.glob(copes_template):
            if any(subj in x for subj in subject_list):
                temp_list.append(x)
        out_list = [x for x in temp_list if contrast in x]
        return out_list

    get_copes = pe.Node(Function(
        input_names=['subject_list', 'copes_template', 'contrast'],
        output_names=['out_list'],
        function=get_files),
                        name='get_copes')
    # get_copes.inputs.subject_list = # From inputspec
    # get_copes.inputs.copes_template = # From inputspec.
    # get_copes.inputs.contrast = # From inputspec.

    ################## Merge into 4d files.
    merge_copes = pe.Node(interface=fsl.Merge(dimension='t'),
                    name='merge_copes')
    # merge_copes.inputs.in_files = copes

    ################## Level 2 design.
    level2model = pe.Node(interface=fsl.MultipleRegressDesign(),
                        name='level2model')
    # level2model.inputs.contrasts # from get_con_info
    # level2model.inputs.regressors # from get_con_info

    ################## Fit mask, if given 2 design.
    if mask:
        def fit_mask(mask_file, ref_file):
            from nilearn.image import resample_img
            import nibabel as nib
            import os
            out_file = resample_img(nib.load(mask_file),
                                   target_affine=nib.load(ref_file).affine,
                                   target_shape=nib.load(ref_file).shape[0:3],
                                   interpolation='nearest')
            nib.save(out_file, os.path.join(os.getcwd(), mask_file.split('.nii')[0]+'_fit.nii.gz'))
            out_mask = os.path.join(os.getcwd(), mask_file.split('.nii')[0]+'_fit.nii.gz')
            return out_mask
        fit_mask = pe.Node(Function(
            input_names=['mask_file', 'ref_file'],
            output_names=['out_mask'],
            function=fit_mask),
                            name='fit_mask')

    ################## FSL Randomize.
    randomise = pe.Node(interface=fsl.Randomise(), name = 'randomise')
    # randomise.inputs.in_file = #From merge_copes
    # randomise.inputs.design_mat = # From level2model design_mat
    # randomise.inputs.tcon = # From level2model design_con
    # randomise.inputs.cm_thresh = 2.49 # mass based cluster thresholding. Not used.
    # randomise.mask = # Provided from mask_reslice, if mask provided.
    randomise.inputs.tfce = True
    randomise.inputs.raw_stats_imgs = True
    randomise.inputs.vox_p_values = True
    # randomise.inputs.num_perm = 5000

    def adj_minmax(in_file):
        import nibabel as nib
        import numpy as np
        import os
        img = nib.load(in_file[0])
        data = img.get_data()
        img.header['cal_max'] = np.max(data)
        img.header['cal_min'] = np.min(data)
        nib.save(img, in_file[0])
        return in_file

    ################## Setup datasink.
    from nipype.interfaces.io import DataSink
    import os
    # sinker = pe.Node(DataSink(parameterization=False), name='sinker')
    sinker = pe.Node(DataSink(parameterization=True), name='sinker')

    ################## Setup Pipeline.
    lvl2tfce_wf.connect([
        (inputspec, make_outdir, [('output_dir', 'output_dir'),
                                 ('proj_name', 'proj_name')]),
        (inputspec, get_model_info, [('full_cons', 'full_cons'),
                                    ('con_regressors', 'con_regressors')]),
        (inputspec, get_model_info, [('contrast', 'contrast')]),
        (inputspec, get_copes, [('subject_list', 'subject_list'),
                               ('contrast', 'contrast'),
                               ('copes_template', 'copes_template')]),
        (get_copes, merge_copes, [('out_list', 'in_files')]),
        (get_model_info, level2model, [('con_info', 'contrasts')]),
        (get_model_info, level2model, [('reg_info', 'regressors')]),
        (merge_copes, randomise, [('merged_file', 'in_file')]),
        (level2model, randomise, [('design_mat', 'design_mat')]),
        (level2model, randomise, [('design_con', 'tcon')]),
        ])
    if mask:
        lvl2tfce_wf.connect([
            (inputspec, fit_mask, [('mask_file', 'mask_file')]),
            (merge_copes, fit_mask, [('merged_file', 'ref_file')]),
            (fit_mask, randomise, [('out_mask', 'mask')]),
            (inputspec, make_outdir, [('mask_file', 'mask')]),
            (fit_mask, sinker, [('out_mask', 'out.@mask')]),
            ])

    lvl2tfce_wf.connect([
        (inputspec, sinker, [('sinker_subs', 'substitutions')]),
        (make_outdir, sinker, [('new_out_dir', 'base_directory')]),
        (level2model, sinker, [('design_con', 'out.@con')]),
        (level2model, sinker, [('design_grp', 'out.@grp')]),
        (level2model, sinker, [('design_mat', 'out.@mat')]),
        (randomise, sinker, [(('t_corrected_p_files', adj_minmax), 'out.@t_cor_p')]),
        (randomise, sinker, [(('tstat_files', adj_minmax), 'out.@t_stat')]),
        ])
    return lvl2tfce_wf
    
import os
import nipype.pipeline.engine as pe # pypeline engine
from nipype import IdentityInterface

full_cons = {
    'cope1': [('cope1', 'T', ['cope1'], [1])],
    'cope2': [('cope2', 'T', ['cope2'], [1])],
    'cope3': [('cope3', 'T', ['cope3'], [1])],
    'cope4': [('cope4', 'T', ['cope4'], [1])],
    'cope5': [('cope5', 'T', ['cope5'], [1])],
    'cope6': [('cope6', 'T', ['cope6'], [1])]
}

subject_list = ['sub-018','sub-019','sub-020','sub-025','sub-026','sub-031','sub-032','sub-041','sub-055','sub-056','sub-058','sub-059','sub-062','sub-064','sub-065','sub-067','sub-070','sub-072','sub-080','sub-088','sub-091']

######################combine all run files per subject######################
# import nibabel as nib
# import statistics, glob
# import numpy as np
# import os

# cope_files = glob.glob('/scratch/data/smooth/sub-*/model/fwhm_5.0_sub-*/_modelestimate0/cope*nii.gz')

# combined_run_data = np.empty(len(subject_list), dtype=object)
# for x, subj_name in enumerate(subject_list):
#     print(subj_name)
#     sub_files = [i for i in cope_files if subj_name in i] 
#     all_runs_files = np.empty(len(sub_files), dtype=object)
#     for y, run_name in enumerate(sub_files):
#         # print(run_name)
#         run_file = nib.load(sub_files[y])
#         run_file_data = run_file.get_data()
#         all_runs_files[y]=run_file_data
#     all_runs_files = np.stack([i for i in all_runs_files],axis=3)
    
#     combined_run_data[x] = np.mean(all_runs_files, axis=3)

#     ref = nib.load(cope_files[0])
#     ref.header['cal_max'] = np.max(combined_run_data[x]) # adjust min and max header info.
#     ref.header['cal_min'] = np.min(combined_run_data[x])
#     out_img = nib.Nifti1Image(combined_run_data[x], ref.affine, ref.header)
#     nib.save(out_img, os.path.join('/scratch/data', subj_name + '_combined_cope1'))
# #############################################################################

lvl2_tfce_wf = create_lvl2tfce_wf()
lvl2_tfce_wf.inputs.inputspec.proj_name = os.environ['FWHM']

# NOTE: modify this according to the output of level 1 modeling.
if os.environ['FWHM'] == 'nosmooth':
    lvl2_tfce_wf.inputs.inputspec.copes_template = '/scratch/data/nosmooth/sub-*/model/_sub-*/_modelestimate0/cope*nii.gz'
elif os.environ['FWHM'] == '1.5':
    lvl2_tfce_wf.inputs.inputspec.copes_template = '/scratch/data/smooth/sub-*/model/fwhm_1.5_sub-*/_modelestimate0/cope*nii.gz'
elif os.environ['FWHM'] == '5':
    lvl2_tfce_wf.inputs.inputspec.copes_template = '/scratch/data/smooth/sub-*/model/fwhm_5_sub-*/_modelestimate0/cope*nii.gz'
else:
    print('cannot match a valid template to the FWHM given. Try again.')
    exit()

# lvl2_tfce_wf.inputs.inputspec.copes_template = '/scratch/data/sub-*_combined_cope*.nii'
# lvl2_tfce_wf.inputs.inputspec.copes_template = '/scratch/data/smooth/sub-*/model/fwhm_5.0_sub-*/_modelestimate0/cope*nii.gz'

lvl2_tfce_wf.inputs.inputspec.output_dir = '/scratch/output'
lvl2_tfce_wf.inputs.inputspec.subject_list = subject_list
lvl2_tfce_wf.inputs.inputspec.full_cons = full_cons
# lvl2_tfce_wf.inputs.inputspec.con_regressors = {}
lvl2_tfce_wf.inputs.inputspec.con_regressors = {
    'cope1': {'cope1': [1] * len(subject_list)},
    'cope2': {'cope2': [1] * len(subject_list)},
    'cope3': {'cope3': [1] * len(subject_list)},
    'cope4': {'cope4': [1] * len(subject_list)},
    'cope5': {'cope5': [1] * len(subject_list)},
    'cope6': {'cope6': [1] * len(subject_list)}
}
# lvl2_tfce_wf.inputs.inputspec.sinker_subs = []
lvl2_tfce_wf.inputs.inputspec.sinker_subs = [
    ('tstat', 'raw_tstat'),
    ('tfce_corrp_raw_tstat', 'tfce_corrected_p'),
    ('contrast_cope1', 'contrast_pain_CS'),
    ('contrast_cope2', 'contrast_pain_ExpRating'),
    ('contrast_cope3', 'contrast_pain_rating'),
    ('contrast_cope4', 'contrast_pain_US'),
    ('contrast_cope5', 'contrast_pain_Val'),
    ('contrast_cope6', 'contrast_pain_PE')
]

####### MASK #####################
# lvl2_tfce_wf.inputs.inputspec.mask_file = '/home/neuro/atlases/FSMAP/stress/masks/amygdala_bl.nii.gz'

def con_dic_to_list(full_cons):
   con_list = []
   for entry in list(full_cons.values())[:]:
       con_list.append(entry[0][0])
   return con_list

infosource = pe.Node(IdentityInterface(fields=['contrast']),
           name='infosource')
infosource.iterables = [('contrast', con_dic_to_list(full_cons))]
# lvl2_tfce_wf.inputs.inputspec.contrast = 'cope1'

full_wf = pe.Workflow(name='full_wf')
full_wf.base_dir = '/scratch/wrkdir'

full_wf.connect([
    (infosource, lvl2_tfce_wf, [('contrast', 'inputspec.contrast')])])

###############note to self
#because we only have one contrast here
#the above infosource.iterables will not work
#comment this part out and use the original script for more than one cope
# lvl2_tfce_wf.inputs.inputspec.contrast = 'cope1'
###############note to self

#### Visualize ################
# full_wf.write_graph('simple.dot')
# from IPython.display import Image
# import os
# Image(filename= os.path.join(full_wf.base_dir, 'full_wf','simple.png'))
full_wf.run(plugin='MultiProc', plugin_args={'n_procs': 6})






