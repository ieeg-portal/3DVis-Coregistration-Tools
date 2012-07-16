for i in `seq 3 9`; do echo 000$i >> ims.txt; done
for i in `seq 10 99`; do echo 00$i >> ims.txt; done
for i in `seq 100 120`; do echo 0$i >> ims.txt; done
for i in `cat ims.txt`
do
  TileImageFilter 1 1 2 MSEL397_MRI.nii.gz IM-0113-${i}.jpg MSEL397_MRI.nii.gz
done

