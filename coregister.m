% COREGISTER
%
%
%
% OUTPUTS:
%
% pre_resection_electrode_seg.nii.gz: prior-based segmentation
%       of pre-resection T1 image
% post_resection_electrode_seg.nii.gz: segmentation file showing electrodes
%       and resected area
% log_{ptName}.txt: log file with command line printouts of all programs
%
%
% EXTERNAL FILE REQUIRMENTS
% 1. util directory (should be within 3DVis directory) conaining:
%       init.txt
%       folder with templates and labels
% 2. inputs-outputs directory containing:
%       T1 MRI
%       CT
%       T2 post-resection MRI (optional)
%       binary mask of resected region (optional)
% 3. lib directory (should be within 3DVis directory) containing:
%       ANTS binaries
%       antsIntroduction.sh (shell script)
%       ITK-SNAP
%       c3d
%       FSL with BET
%       Nifti toolbox for Matlab
%       systemf_db.m
%       digElectrodes.m
% -------------------------------------------------------------------------


% USER INPUT
%
% ****FIRST USE ONLY****
%
% COPY THE FOLLOWING COMMANDS DIRECTLY INTO THE TERMINAL FROM WITHIN THE
% 3DVIS/UTIL DIRECTORY. REPLACE THE <insert path here> IN STEP 1 WITH THE
% PATH TO THE 3DVIS DIRECTORY (THIS PATH SHOULD END WITH /3DVIS AND CAN BE
% DETERMINED BY NAVIGATING TO THE 3DVIS DIRECTORY FROM THE TERMINAL AND
% TYPING 'pwd').
%
% 1) sed '1 i VISPATH=<insert path here>' init.txt >> ~/.bash_profile
% 2) source ~/.bash_profile


% -------------------------------------------------------------------------
% --------------------------REQUIRED INPUTS--------------------------------
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
% DIRECTORIES AND PATIENT-SPECIFIC DATA FILENAMES (WITHOUT EXTENSIONS)
%--------------------------------------------------------------------------

% T1, T2 and CT images are assumed to have the same orientation as the
% template

% (short) patient name/id
ptName = 'hup72';

% Location of 3DVis directory
vispath='/mnt/local/gdrive/public/3DVis';

% Location of input-output diretory (no trailing filesep)
in_out='/mnt/local/gdrive/public/pearce/side_projects/3DVis/hup72';

% Pre-resection patient T1 MR image (high resolution) (nii.gz)
T1='mri72';

% CT image with electrodes (nii.gz)
CT='ct72';

% Post-resection patient T2 MR image (nii.gz)
T2=[]; %'Mayo34_MRI_post';

% Binary image of resected region in T2 image (nii.gz)
resection=[]; %'Mayo34_resected_area';

%--------------------------------------------------------------------------
% RUN OPTIONS
%--------------------------------------------------------------------------
% Segmentation mode (set to '1' if you want 35 brain regions +
% electrodes, 0 for just electrodes on brain. 0 is much faster)
segment = 1;

% Resection mode (set to '1' if you have post-resection data, otherwise 0)
resect = 0;

% Float all electrodes to surface of brain (set to 0 for depth electrodes)
unbury = 1;

% Debug mode (set to '1' for command printouts)
db = 0;

% Clean up mode (set to '1' to delete intermediate files at end)
cleanup = 1;

% Intensity threshold for locating electrodes in CT. Assume that electrodes
% have higher intensity than "electrode_thresh" and everything else is
% lower
electrode_thresh=2000;
% -------------------------------------------------------------------------
% -------------------------END REQUIRED INPUTS-----------------------------
% -------------------------------------------------------------------------




%-------------------------------------------------------------------------
% OTHER INIT
%--------------------------------------------------------------------------
T1path = [in_out filesep 'temp' filesep T1];
CTpath = [in_out filesep 'temp' filesep CT];
if resect==1
    T2path = [in_out filesep T1];
    resectionPath = [in_out filesep resection];
end

% External intensity template (nii.gz)
template='NIREPG1template';
templatePath=[vispath '/util/templates/' template];

% Labels accompanying template (nii.gz)
templateLabels='NIREPG1template_35labels';
templateLabelsPath=[vispath '/util/templates/' templateLabels];

% Prefix for warp output filename (should not be the same as template file main body)
warpOutputPrefix='NIREP';

% Smoothness parameter for prior-based segmentation. The bigger the
% parameter is, the smoother the segmentation. is. Normal range 0.05 to 0.5.
MRF_smoothness=0.1;

% Log file where command line output will be written (.txt)
log = sprintf('%s/log_%s.txt',in_out,ptName);

% add functions to MATLAB path
addpath(sprintf('%s/util/',vispath));
addpath(sprintf('%s/lib/etc',vispath));
addpath(sprintf('%s/lib/nifti',vispath));

% move inputs to temporary working directory
cd(in_out);
mkdir temp
tmpDir = [in_out '/temp/'];
systemf_db(db, 'cp %s.nii.gz temp/', T1)
systemf_db(db, 'cp %s.nii.gz temp/', CT)
if resect
    systemf_db(db, 'cp %s.nii.gz temp/', resection)
    systemf_db(db, 'cp %s.nii.gz temp/', T2)
end
cd temp

%% ------------------------------------------------------------------------
% MAIN
% -------------------------------------------------------------------------

% SKULL STRIPPING
fprintf('\nRunning bet2 to strip the skull...\n')
systemf_db(db, 'bet2 %s.nii.gz %s_brain -m >> %s', T1path, T1path, log)
fprintf('Done with skull stripping\n\n')

% NON-RIGID WARPING
if segment
    fprintf('Performing non-rigid registration with ANTS (may take hours)...\n')
    systemf_db(db, ['antsIntroduction.sh -d 3 -r %s.nii.gz -i %s_brain.nii.gz -o ' ...
        '%s_ -m 30x90x20 -l %s.nii.gz >> %s'], templatePath, T1path, ...
        warpOutputPrefix, templateLabelsPath, log)
    fprintf('Done with ANTS non-rigid registration\n\n')
end

% PRIOR-BASED SEGEMENTATION ON WARPED LABELS
if segment
    fprintf('Performing prior-based segmentation\n')
    mkdir priorBasedSeg
    cd priorBasedSeg
    for i = 1:35
        systemf_db(db,['ThresholdImage 3 ../%s_labeled.nii.gz label%02d.nii.gz ' ...
            '%d %d >> %s'], warpOutputPrefix, i, i, i, log)
        systemf_db(db, ['ImageMath 3 label_prob%02d.nii.gz G label%02d.nii.gz 3 ' ...
            '>> %s'], i, i, log)
    end
    fprintf('\tThis will take a while...\n')
    systemf_db(db,['Atropos -d 3 -a %s.nii.gz -x %s_brain_mask.nii.gz -i '...
        'PriorProbabilityImages[35,./label_prob%%02d.nii.gz,0.5] -m [%g,1x1x1] ' ...
        '-c [5,0] -p Socrates[0] -o [./NIREP_seg35labels_prior0.5_mrf%g.nii.gz] '...
        '>> %s'], T1path, T1path, MRF_smoothness, MRF_smoothness, log)
    systemf_db(db, ['cp NIREP_seg35labels_prior0.5_mrf%g.nii.gz ' ...
        '../seg35labels_prior0.5_mrf%g.nii.gz'], MRF_smoothness, MRF_smoothness)
    fprintf('Done with prior-based segmentation\n')
    cd ..
end


% CT ALIGNMENT (RIGID REGISTRATION) AND ELECTRODE EXTRACTION
fprintf('Running ANTS rigid registration (shouldn''t take too long)...\n')
systemf_db(db,['antsIntroduction.sh -d 3 -r %s.nii.gz -i %s.nii.gz -o '...
    '%s_ -t RA -s MI >> %s'], T1path, CTpath, CTpath, log)
% use brain mask to limit electrode wires/noise included from CT
systemf_db(db, ['c3d %s_brain_mask.nii.gz %s_deformed.nii.gz -multiply -o' ...
    ' %s_deformed_brainOnly.nii.gz >> %s'], T1path, CTpath, CTpath, log)
systemf_db(db, ['c3d %s_deformed_brainOnly.nii.gz -threshold %g 99999 1 0 -o ' ...
    'electrode_aligned.nii.gz >> %s'], CTpath, electrode_thresh, log)
fprintf('Done with rigid registration\n\n')
if unbury
    % make sure electrodes aren't buried in tissue
    systemf_db(db, 'cp electrode_aligned.nii.gz electrodes_original.nii.gz'); % file is overwritten in next function
    digElectrodes([T1path '_brain_mask.nii.gz'], ...
        [in_out filesep 'temp/electrode_aligned.nii.gz']);
end
% combine electrodes with brain mask (no segmentation)
if ~segment
    systemf_db(db, ['c3d electrode_aligned.nii.gz -scale ' ...
        '2 %s_brain_mask.nii.gz -add -clip 0 2 -o ' ...
        '%s_electrode_seg.nii.gz >> %s'], ...
        T1path, ptName, log)
    systemf_db(db, 'mv %s_electrode_seg.nii.gz %s/', ptName, in_out)
else
    % combine electrodes with T1 segmentation
    fprintf('Combining electrodes with T1 segmentation\n')
    systemf_db(db, ['c3d electrode_aligned.nii.gz -scale ' ...
        '40 seg35labels_prior0.5_mrf%g.nii.gz -add -clip 0 40 -o ' ...
        '%s_electrode_seg.nii.gz >> %s'], MRF_smoothness, ptName, log)    
    systemf_db(db, 'mv %s_electrode_seg.nii.gz %s/', ptName,in_out)
end

%% Post-resection
if resect==1
    % align post-resection to pre-resection
    fprintf('Calling ANTS to align post-resction T1 to pre-resection T1...\n')
    systemf_db(db, ['antsIntroduction.sh -d 3 -r %s.nii.gz -i %s.nii.gz -o %s_'...
        ' -t RI -s MI >> %s'], T1path, T2path, T2path, log)
    fprintf('Done with alignment\n')
    
    % transform resected region from post-resection to pre-resection
    fprintf('Transforming resected region from T2 to T1...\n')
    systemf_db(db, ['WarpImageMultiTransform 3 %s.nii.gz %s_aligned.nii.gz -R ' ...
        '%s.nii.gz %s_Affine.txt >> %s'], resectionPath, resectionPath, ...
        T1path, T2path, log)
    fprintf('Done transforming resection\n')
    
    % combine the resected cortex (brain mask minus resection) and the electrodes
    fprintf('Combining resected cortex and electrodes...\n')
    systemf_db(db, ['c3d %s_brain_mask.nii.gz %s_aligned.nii.gz -thresh 0.99 99 '...
        '2 0 -add -clip 0 2 electrode_aligned.nii.gz -scale 3 -add -clip 0 3 ' ...
        '-o ElectrodesOnResectedCortex.nii.gz >> %s'], T1path, resectionPath, log)
    fprintf('Done\n')
    
    % combine segmentation, resection, and eletrodes
    fprintf('Combining segmented, resected cortex with electrodes...\n')
    systemf_db(db, ['c3d  seg35labels_prior0.5_mrf%g.nii.gz ' ...
        ' %s_aligned.nii.gz -scale 39 -add -clip 0 39 electrode_aligned.nii.gz' ...
        ' -scale 40 -add -clip 0 40 -o %s_post_resection_seg.nii.gz >> %s'],...
        MRF_smoothness, resectionPath, ptName, log)
    fprintf('Done\n')
    systemf_db(db, 'mv %s_post_resection_seg.nii.gz  %s/', ptName, in_out)
    systemf_db(db, 'mv %s_brain.nii.gz %s/', T1path, in_out)
end

cd ..

%% CLEAN UP INTERMEDIATE FILES----------------------------------------------
if cleanup == 1
    systemf_db(db, 'rm -r temp');
end

% stop the timer
time = toc;
fprintf('Total execution time: %d hours\n', time/3600);


