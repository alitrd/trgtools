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
def_indatapath="/lustre/alice/alien/alice/data"
def_outdatapath="/lustre/alice/pachmay_2/trd_trigger"

indatapath=$def_indatapath
outdatapath=$def_outdatapath
scriptpath=`dirname $(readlink -f $0)`
ocdbpath=$indatapath
runlocal=0

alirootversion="dev"
detectors="ITS TPC TRD TOF"
rec_options="dc"
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
sleep 2;

# count jobs already submitted
njobs=0;

if [[ "$runnr" =~ '^[0-9]*$' ]]; then
  echo 0
  run=`printf %09d $runnr`
  filelist=`find $indatapath/*/*/$run/raw -iname "[0-9]*\.[0-9]*\.root"`
else
  echo 1
  run=`basename $runnr | sed -e 's/\..*//g'`
  filelist=`cat $runnr`
fi

[[ -d $outdatapath/$run ]] || mkdir -p $outdatapath/$run
pushd $outdatapath/$run

for file in $filelist; do 

    chunk=`basename $file .root`;
    year=20${chunk:0:2}
    period=`echo $file | sed -e 's/.*\(LHC[0-9].[^\/]\)\/.*/\1/g'`
    echo $year $chunk;
    [[ -d $chunk ]] || mkdir $chunk

    if [ "$ocdbother" -eq 1 ]; then
      ocdb=${ocdbpath}
    else
      ocdb="local://${ocdbpath}/${year}/OCDB"
    fi

    m4 -D ___OCDB___=$ocdb \
       -D ___FILENAME___=$file \
       -D ___NEVENTS___=$nevents \
       -D ___STARTEVENT___=$startevent \
       -D ___RECDETECTORS___="$detectors" \
       -D ___TRD_RECOPTIONS___="$rec_options" \
       ${scriptpath}/rec.C.m4 > $chunk/rec.C

    # skip chunk if we don't find it
    [[ -e $file ]] || continue;
    # skip chunk if it's already reconstructed
    [[ -e $chunk/AliESDs.root ]] && continue;
    # or if queued
    [[ -e $chunk/.queued ]] && continue;

    # if max no of jobs not yet exceeded submit the job
    if [ $njobs -ge $maxjobs ]; then
	    break;
    fi;

    #  #BSUB -oo rec-%J-%I-out.log
    #  #BSUB -eo rec-%J-%I-err.log

    command=". ${scriptpath}/alijkl $alirootversion; cd $chunk; printenv > environment.log; aliroot -l -q -b ./rec.C;"

    if [ "x$queue" == "xrunlocal" ]; then
      echo "Executing locally..." 
      (
        eval "$command" > "$chunk/reco.local.log" 2>&1
      )

    elif [ "x$queue" == "xnorun" ]; then
      echo "Not running reconstruction..."

    else
      echo "#!/bin/sh
        #BSUB -o $chunk/reco.batch.log
        #BSUB -q $queue
        #BSUB -J rec-$chunk
        $command" | bsub
  
      touch $chunk/.queued
    fi
  
    njobs=$(($njobs + 1));
done

popd
