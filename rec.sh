#!/bin/bash

function show_help() {
  echo "Reconstruction script"
  echo "  Usage: `basename $0` [options] <input>"
  echo "         <input> is interpreted as run number if it contains digits only,"
  echo "         otherwise as file containing one chunk per line."
  echo "  Options:"
  echo "    -q <q>    Specify batch queue to submit to"
  echo "    -l        Run on local machine (useful for testing)"
  echo "    -o <o>    Specify output directory (default: $def_outdatapath)"
  echo "    -d <p>    Specify input data base path (default: $def_indatapath)"
  echo "                [Normally derived automatically from run number or list of chunks]"
  echo "    -b <p>    Specify OCDB base path (default: $def_indatapath)"
  echo "                [Normally automatically derived]"
  echo "    -m <i>    Limit maximum number of jobs (=chunks) to submit to <i>"
  echo "    -n <i>    Process <i> events per chunk, starting from <s>"
  echo "    -s <i>    Specify start event <s>"
  echo "    -v <c>    Specify aliroot version to use (default: dev)"
  echo "    -h        Show this help"
}

#--------------------------------------------------------------------------------
scriptpath=`dirname $(readlink -f $0)`

[[ -f ${scriptpath}/batch.sh ]] && source ${scriptpath}/batch.sh || exit -1

farm=`farm`
if [[ $farm =~ pro|ica ]]; then
    def_indatapath="/hera/alice/alien/alice/data"
    def_outdatapath="/hera/alice/$(whoami)/reco/test"
    ocdbpath="/cvmfs/alice.gsi.de/alice/data"
elif [ $farm = lenny64 ]; then
    def_indatapath="/lustre/alice/alien/alice/data"
    def_outdatapath="/lustre/alice/$(whoami)/reco/test"
    ocdbpath=$def_indatapath
fi

indatapath=$def_indatapath
outdatapath=$def_outdatapath
runlocal=0

alirootversion="dev"
detectors="ITS TPC TRD TOF V0"
#detectors="TRD"
rec_options="dc,sa"
nevents=10001
startevent=0
maxjobs=10
ocdbother=0
queue=alice-t3_2h

while getopts "hq:m:n:Ns:d:v:lo:b:" OPTION
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
    s)  startevent=$OPTARG
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
    ?)  show_help
        exit 1
        ;;
    esac
done
shift $(($OPTIND - 1))

if [ $# -lt 1 ]; then
    show_help
    exit 1;
fi;

runnr=$1

#--------------------------------------------------------------------------------
echo "#-------------------------------------------------------------------"
echo "#  RunNumber:      $runnr"
echo "#  Queue:          $queue"
echo "#  MaxJobs:        $maxjobs"
echo "#  DatapathIn:     $indatapath"
echo "#  DatapathOut:    $outdatapath"
echo "#  AliRootVersion: $alirootversion"
echo "#    nevents: $nevents     startevent: $startevent"
echo "#-------------------------------------------------------------------"
#--------------------------------------------------------------------------------

echo "Runnumber: $runnr"
echo "Max no. of jobs to be submitted: $maxjobs"

# count jobs already submitted
njobs=0;
jobtype=rec

if [[ "$runnr" =~ ^[0-9]*$ ]]; then
  echo 0
  run=`printf %09d $runnr`
  echo $run
  filelist=`find $indatapath/*/*/${run} -iname "[0-9]*\.[0-9]*\.root" -or -iname "galice.root"`
else
  echo 1
  run=`basename $runnr | sed -e 's/\..*//g'`
  filelist=`cat $runnr`
fi;

[[ -d $outdatapath ]] || mkdir -p $outdatapath
pushd $outdatapath

for file in $filelist; do 

    echo $file

    # if max no of jobs not yet exceeded submit the job
    if [ $njobs -ge $maxjobs ]; then
	    break;
    fi;

    if [[ $file =~ 'galice' ]]; then
	sim=1;
	chunk=`dirname $file`;
	inputfile="0x0";
    else
	sim=0;
	chunk=$run/`basename $file .root`;
	filename=`basename $file .root`;
	year=20${filename:0:2}
	period=`echo $file | sed -e 's/.*\(LHC[0-9].[^\/]\)\/.*/\1/g'`
	inputfile="\"$file\"";
    fi;

    # skip chunk if we don't find it
    [[ -e $file ]] || continue;
    # skip chunk if it's already reconstructed
    [[ -e $chunk/AliESDs.root ]] && continue;
    # or if queued
    [[ -e $chunk/.queued_${jobtype} ]] && continue;

    [[ -d $chunk ]] || mkdir -p $chunk

    if [ "$ocdbother" -eq 1 ]; then
      ocdb=${ocdbpath}
    elif [ $sim -eq 1 ]; then
      ocdb='local://$ALICE_ROOT/OCDB';
      extra="man->SetSpecificStorage(\"GRP/GRP/Data\", Form(\"local://%s\",gSystem->pwd()));"
    else
      ocdb="local://${ocdbpath}/${year}/OCDB"
    fi

    workdir=`readlink -f ${chunk} | sed -e 's#/SAT##'`

    # prepare rec.C
    m4 -D ___OCDB___=$ocdb \
       -D ___INPUTFILE___=$inputfile \
       -D ___NEVENTS___=$nevents \
       -D ___STARTEVENT___=$startevent \
       -D ___RECDETECTORS___="$detectors" \
       -D ___TRD_RECOPTIONS___="$rec_options" \
       -D ___EXTRA___="$extra" \
       ${scriptpath}/macros/recCPass0.C.m4 > $chunk/rec.C

    # prepare the run script
    m4  -D ___SCRIPTPATH___=${scriptpath} \
	-D ___ALIROOT_VERSION___=${alirootversion} \
	-D ___WORKDIR___=${workdir} \
	${scriptpath}/scripts/run${jobtype}.sh.m4 > $chunk/run${jobtype}.sh
    chmod u+x $chunk/run${jobtype}.sh

    # copy list of files to be removed after reconstruction
    cp ${scriptpath}/remove.lst ${workdir}/

    # copy the script to setup the environment
    cp ${scriptpath}/alisetup.${farm} ${workdir}/alisetup

    if [ "x$queue" == "xrunlocal" ]; then
	echo "Executing locally..." 
	( ${chunk}/run${jobtype}.sh > "$chunk/${jobtype}.local.log" 2>&1 )

    elif [ "x$queue" == "xnorun" ]; then
	echo "Not running reconstruction..."

    else
  	submit ${jobtype} ${workdir} run${jobtype}.sh ${queue}

	touch $chunk/.queued_${jobtype}
    fi
  
    njobs=$(($njobs + 1));
done

popd
