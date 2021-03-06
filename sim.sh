#!/bin/bash

function show_help() {
  echo "Simulation script"
  echo "  Usage: `basename $0` [options]"
  echo "  Options:"
  echo "    -q <q>    Specify batch queue to submit to"
  echo "    -l        Run on local machine (useful for testing)"
  echo "    -o <o>    Specify output directory (default: $def_outdatapath)"
  echo "    -b <p>    Specify OCDB base path (default: $def_ocdbpath)"
  echo "                [Normally automatically derived]"
  echo "    -m <i>    Limit maximum number of jobs (=chunks) to submit to <i>"
  echo "    -n <i>    Process <i> events per chunk, starting from <s>"
  echo "    -t <type> process to simulate, e.g. kPythia6Jets104_125 (default: $def_simtype)"
  echo "    -f <type> Specify magnetic field to use (default: $def_bfield)"
  echo "    -v <c>    Specify aliroot version to use (default: $def_alirootversion)"
  echo "    -h        Show this help"
}

#--------------------------------------------------------------------------------
scriptpath=`dirname $(readlink -f $0)`

[[ -f ${scriptpath}/batch.sh ]] && source ${scriptpath}/batch.sh || exit -1

farm=`farm`

if [[ $farm =~ pro|ica ]]; then
    def_ocdbpath="/cvmfs/alice.gsi.de/alice/data"
    def_outdatapath="/hera/alice/$(whoami)/sim/test"
elif [ $farm = lenny64 ]; then
    def_ocdbpath="/lustre/alice/alien/alice/data"
    def_outdatapath="/lustre/alice/$(whoami)/sim/test"
elif [[ $farm =~ kronos ]]; then
    def_ocdbpath="/lustre/nyx/alice/users/hklingen/alicesw/ali-master/AliRoot/OCDB"
    def_outdatapath="/lustre/nyx/alice/users/$(whoami)/sim/test"
fi

def_simtype="kPythia6"
#def_indatapath=""
def_alirootversion="latest-ali-master"
def_bfield="b5p";

outdatapath=$def_outdatapath
ocdbpath=$def_ocdbpath
runlocal=0
alirootversion=$def_alirootversion
simtype=$def_simtype
bfield=$def_bfield
nevents=1
maxjobs=1
ocdbother=0
queue=runlocal

while getopts "hq:m:n:Ns:d:v:lo:b:t:f:" OPTION
do
  case $OPTION in
    h)  show_help
        exit 0
        ;;
    q)  queue=$OPTARG
        ;;
    l)  queue="runlocal"
        ;;
    N)  queue="norun"
        ;;
    m)  maxjobs=$OPTARG
        ;;
    n)  nevents=$OPTARG
        ;;
    d)  indatapath=$OPTARG
        ;;
    v)  alirootversion=$OPTARG
        ;;
    o)  outdatapath=$OPTARG
        ;;
    b)  ocdbpath=$OPTARG
        ocdbother=1
        ;;
    t)  simtype=$OPTARG
	;;
    f)  bfield=$OPTARG
	;;
    ?)  echo "Unknown option: $OPTION"
	show_help
        exit 1
        ;;
    esac
done
shift $(($OPTIND - 1))

if [[ $bfield == "b5n" ]]; then
    scalebfield=-1.;
elif [ $bfield == "b5p" ]; then
    scalebfield=1.;
elif [ $bfield == "b0" ]; then
    scalebfield=0.;
else
    echo "Unknown B-field";
    exit -1;
fi;

#--------------------------------------------------------------------------------
echo "#-------------------------------------------------------------------"
echo "#  Queue:          $queue"
echo "#  MaxJobs:        $maxjobs"
echo "#  DatapathIn:     $indatapath"
echo "#  DatapathOut:    $outdatapath"
echo "#  AliRootVersion: $alirootversion"
echo "#  nevents:        $nevents"
echo "#-------------------------------------------------------------------"
#--------------------------------------------------------------------------------

echo "Max no. of jobs to be submitted: $maxjobs"

# count jobs already submitted
ijob=-1;
njobs=0;
jobtype=sim

[[ -d $outdatapath ]] || mkdir -p $outdatapath
pushd $outdatapath || exit -1

while [ true ]; do

    # if max no of jobs not yet exceeded submit the job
    if [ $njobs -ge $maxjobs ]; then
	break;
    fi;

    ijob=$((1+$ijob))

    chunk=${bfield}/${simtype}/`printf %09d $ijob`

    # skip chunk if it's already simulated
    [[ -e $chunk/galice.root ]] && continue;
    # or if queued
    [[ -e $chunk/.queued_${jobtype} ]] && continue;

    mkdir -p $chunk

    if [ "$ocdbother" -eq 1 ]; then
      ocdb=${ocdbpath}
    else
      ocdb="local://${ocdbpath}"
      #ocdb="local://${ocdbpath}/${year}/OCDB"
    fi

    # prepare sim.C
    m4 -D ___OCDB___=$ocdb \
       -D ___NEVENTS___=$nevents \
       ${scriptpath}/macros/sim.C.m4 > $chunk/sim.C

    # prepare Config.C
    m4 -D ___SIMTYPE___=$simtype \
       -D ___SCALEB___=$scalebfield \
       ${scriptpath}/macros/Config.C.m4 > $chunk/Config.C

    # prepare the run script
    m4  -D ___SCRIPTPATH___=${scriptpath} \
	-D ___ALIROOT_VERSION___=${alirootversion} \
	-D ___WORKDIR___=${outdatapath}/${chunk} \
	${scriptpath}/scripts/run${jobtype}.sh.m4 > $chunk/run${jobtype}.sh
    chmod u+x $chunk/run${jobtype}.sh

    # copy the script to setup the environment
    cp ${scriptpath}/alisetup.${farm} ${outdatapath}/${chunk}/alisetup

    if [ "x$queue" == "xrunlocal" ]; then
	echo "Executing locally..."
	( ${chunk}/run${jobtype}.sh > "$chunk/${jobtype}.local.log" 2>&1 )

    elif [ "x$queue" == "xnorun" ]; then
	echo "Not running simulation..."

    else
	submit ${jobtype} ${outdatapath}/${chunk} run${jobtype}.sh ${queue}

	touch $chunk/.queued_${jobtype}
    fi

    njobs=$(($njobs + 1));
done

popd
