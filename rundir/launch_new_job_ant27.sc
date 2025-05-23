#!/bin/bash
shopt -s expand_aliases  # Enables alias expansion.

# FDM settings # copied from run_make_loadscript
export domain="ANT27"
forcing="era027"
export project_name="run-1979-2023-ANT27-era027_test"  #"run-1979-2023-ANT27-era027_test4"
export restart_type="none" # none - do spinup; spinup - restart from spinup; (testing -> run - restart from run)

export outputname="${domain}_${forcing}"
export runname="${domain}_${project_name}" 
#export p2input="$HPCPERM/${domain}_${forcing}/reference/IN_ll_FGRN055_GrIS_GIC_implicit.txt"
#export p2input="$HPCPERM/IMAU_FDM/code/reference/IN_ll_ANT27_evaluation.txt"
export p2exe="$PERM/IMAU_FDM/code/Github/IMAU-FDM/"
export p2input="${p2exe}/reference/${domain}/IN_ll_ANT27_CB1979-2020_nor.txt"
export FDM_executable="imau-fdm.x"
export homedir=`pwd`
gridpointlist="$homedir/pointlists/pointlist_${project_name}.txt"

export workdir="${SCRATCH}/${project_name}"
export outputdir="${SCRATCH}/${project_name}/output" #"$SCRATCH/data/output/$expname/" 
export restartdir="${SCRATCH}/restart/${project_name}" #"$SCRATCH/IMAU-FDM_RACMO23p2/RESTART/"
export p2ms="${SCRATCH}/${project_name}/ms_files" #"$SCRATCH/data/ms_files/" # hardcoded in IMAU-FDM
export p2logs="${SCRATCH}/${project_name}/logfiles" #"$SCRATCH/data/logfile/$expname/$runname"
export filename_part1="${outputname}"
# 
export walltime="48:00:00"   # (hms) walltime of the job 
export cooldown="00:00:30"   # (hms) how long prior end should focus shift to completing running jobs?
export hostname="cca"
export relaunch="no"        # with "no", no new iteration will be launched

# other FDM input
export usern=$USER

# likely not to change
export account_no="spnlberg"
export jobname_base="FDM_${project_name}_i"
export nnodes_max=8 #8
export tasks_per_node=64 #64 this is not to be changed
export FDMs_per_node=60 #128 # play around for the optimal performance 
export EC_hyperthreads=1
export memory_per_task="999Mb"
export taskfactor="1."                  # prior launch at least 5. task per core must be available    
export EC_ecfs=0      # number of parallel ECFS calls 

# script misc
export workpointlist="$workdir/pointlist"
export readydir_base="$workdir/readypoints"
export readpointexe="$homedir/readpointlist/readpointlist.x"
export distributor="$homedir/readpointlist/distribute_points.x"
export requestdir="$workdir/requests"
export nplogdir="$workdir/nplogs"
export workexe="$workdir/LocalCode"
export submission_iteration=1

# echo all filepaths to double check
echo "outputdir: ${outputdir}"
echo "restartdir: ${restartdir}"
echo "p2ms: ${p2ms}"
echo "p2logs: ${p2logs}"
echo "outputname: ${outputname}"
echo "p2input: ${p2input}"
echo "p2exe: ${p2exe}"
echo "homedir: ${homedir}"
echo "gridpointlist: ${gridpointlist}"
echo "workdir: ${workdir}"
echo "workpointlist: ${workpointlist}"
echo "readydir_base: ${readydir_base}"
echo "readpointexe: ${readpointexe}"
echo "distributor: ${distributor}"
echo "requestdir: ${requestdir}"
echo "nplogdir: ${nplogdir}"
echo "workexe: ${workexe}"
echo "restart_type=${restart_type}"

echo "Continuing will remove all current files in the workdir!"
echo
read -p "Check paths. Want to continue? (y/n)" -n 1 -r
echo

if [[ $REPLY =~ ^[Yy]$ ]]; then

  # -------- start of the launching procedure -------
  echo "Start cleaning working directory"
  # prepare launch
  mkdir -p $workdir
  rm -rf $workdir/*
  mkdir -p $nplogdir
  mkdir -p $workexe
  mkdir -p $requestdir
  mkdir -p $readydir_base
  mkdir -p $p2ms
  mkdir -p $outputdir
  mkdir -p $restartdir
  mkdir -p $p2logs

  if [[ ! -r $gridpointlist ]]; then
    echo "The grid point list is missing!"
    exit 1
  fi  
  cp $gridpointlist ${workpointlist}.txt
    
  let "ncpu_tot=$nnodes_max*$tasks_per_node"
  echo "Run at max on $tasks_per_node cores on $nnodes_max node(s)."  
  echo "So max parallel jobs is ${ncpu_tot}."

  echo "Create environment file and submittable script."
  ./submit_job.sc

fi


exit 0  
