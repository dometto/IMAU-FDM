#!/bin/ksh 

#SBATCH -J NCL_1d_vtot
#SBATCH -q nf
#SBATCH -e /perm/nld4814/code/IMAU-FDM/post-process//logs/log_NCL_1d_vtot.out
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=e.h.case@uu.nl
#SBATCH --export=ALL
#SBATCH -o /perm/nld4814/code/IMAU-FDM/post-process//logs/log_NCL_1d_vtot.out
#SBATCH --mem-per-cpu=16000mb
#SBATCH --cpus-per-task=1
#SBATCH --time=48:00:00

ncl 'variab="vtotal"' dt=0 atzero=0 /perm/nld4814/code/IMAU-FDM/post-process/make_1d_files/FGRN055_make_one_1d_file.ncl

exit 0
