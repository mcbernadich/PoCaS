#!/bibn/bash
for i in `seq 1 20` ; do
    ftcopy "RC3_CNG+1[#row >= $[(${i}-1)*1200+1] && #row <= $[${i}*1200]]" RC3_CNG_Set${i}
done