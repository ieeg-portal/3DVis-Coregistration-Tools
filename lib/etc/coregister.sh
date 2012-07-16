#!/bin/bash

T1=20070914_mri003a1001.nii.gz # pre-resection
template=NIREPG1template.nii.gz
templateLabels=NIREPG1template_35labels.nii.gz
warpOutputPrefix=NIREP # don't be the same as template file main body
CT=20070914_ct002.nii.gz # with electrodes
electrode_thres=2500
T2=20070922_t2w003.nii.gz # post-resection
resection=20070922_t2w003_resectedRegion.nii.gz
MRF_smoothness=0.1

## strip the skull in T1
#bet2 $T1 ${T1%.nii.gz}_brain -m

## warp the NIREP template to skull-stripped T1
#antsIntroduction.sh -d 3 -r $template -i ${T1%.nii.gz}_brain.nii.gz -o ${warpOutputPrefix}_ -m 30x90x20 -l $templateLabels

# perform prior-based segmentation on the warped labels (may require more memory)
#:<<commentblock
#mkdir priorBasedSeg
#cd priorBasedSeg
 #for i in `seq 1 9`; do echo 0$i >> labels.txt; done
 #for i in `seq 10 35`; do echo $i >> labels.txt; done
 #for i in `cat labels.txt`
#do
  #ThresholdImage 3 ../${warpOutputPrefix}_labeled.nii.gz label${i}.nii.gz $i $i
  #ImageMath 3 label_prob${i}.nii.gz G label${i}.nii.gz 3
#done
Atropos -d 3 -a ../$T1 -x ../${T1%.nii.gz}_brain_mask.nii.gz -i PriorProbabilityImages[35,./label_prob%02d.nii.gz,0.5] -m [${MRF_smoothness},1x1x1] -c [5,0] -p Socrates[0] -o [./NIREP_seg35labels_prior0.5_mrf${MRF_smoothness}.nii.gz]
cp NIREP_seg35labels_prior0.5_mrf${MRF_smoothness}.nii.gz ../seg35labels_prior0.5_mrf${MRF_smoothness}.nii.gz
cd ..
#commentblock

# align CT to T1 and extract the electrodes
#antsIntroduction.sh -d 3 -r $T1 -i $CT -o ${CT%.nii.gz}_ -t RI -s MI
#c3d ${CT%.nii.gz}_deformed.nii.gz -threshold ${electrode_thres} 99999 1 0 -o electrode_aligned.nii.gz

# combine electrodes with T1 segmentation
#c3d electrode_aligned.nii.gz -scale 40 seg35labels_prior0.5_mrf${MRF_smoothness}.nii.gz -add -clip 0 40 -o seg35labels_prior0.5_mrf${MRF_smoothness}_electro.nii.gz
itksnap -g $T1 -s seg35labels_prior0.5_mrf${MRF_smoothness}_electro.nii.gz -l templateCorticalLabels.txt &
#/Users/allie/Code/ITK-SNAP.app/Contents/MacOS/InsightSNAP -g $T1 -s seg35labels_prior0.5_mrf${MRF_smoothness}_electro.nii.gz -l templateCorticalLabels.txt &

## aligned post-resection T2 to (pre-resection) T1
##./antsIntroduction.sh -d 3 -r $T1 -i $T2 -o ${T2%.nii.gz}_ -t RI -s MI

## transform resected region from post-resection T2 to (pre-resection) T1
##WarpImageMultiTransform 3 $resection ${resection%.nii.gz}_aligned.nii.gz -R $T1 ${T2%.nii.gz}_Affine.txt

## combine the resected cortex (brain mask minus resection) and the electrodes
##c3d ${T1%.nii.gz}_brain_mask.nii.gz ${resection%.nii.gz}_aligned.nii.gz -thresh 0.99 99 2 0 -add -clip 0 2 electrode_aligned.nii.gz -scale 3 -add -clip 0 3 -o ElectrodesOnResectedCortex.nii.gz
