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
  echo "    -b <p>    Specify OCDB base path (default: $def_indatapath)"
  echo "    -m <i>    Limit maximum number of jobs (=chunks) to submit to <i>"
  echo "    -n <i>    Process <i> events per chunk, starting from <s>"
  echo "    -s <i>    Specify start event <s>"
  echo "    -v <c>    Specify aliroot version to use (default: dev)"
  echo "    -h        Show this help"
}

#--------------------------------------------------------------------------------
def_indatapath="/lustre/alice/alien/alice/data"
def_outdatapath="/lustre/alice/pachmay_2/trd_trigger"

indatapath=$def_outdatapath
outdatapath=$def_outdatapath
scriptpath=`dirname $(readlink -f $0)`
ocdbpath=$indatapath
runlocal=0

alirootversion="dev"
detectors="ITS TPC TRD TOF"
rec_options="tp,tw,dc"
nevents=10001
startevent=0
maxjobs=10
queue=alice-t3_2h

while getopts "hq:m:n:s:d:v:lo:b:" OPTION
do 
  case $OPTION in
    h)  show_help
        exit 0
        ;; 
    q)  queue=$OPTARG
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
    l)  runlocal=1
        ;;
    o)  outdatapath=$OPTARG
        ;;
    b)  ocdbpath=$OPTARG
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
execmode="BATCH"
if [ "$runlocal" -eq 1 ]; then
  execmode="LOCAL"
fi

echo "#-------------------------------------------------------------------"
echo "#  RunNumber:      $runnr"
echo "#  Queue:          $queue"
echo "#  MaxJobs:        $maxjobs"
echo "#  DatapathIn:     $indatapath"
echo "#  DatapathOut:    $outdatapath"
echo "#  Execution       $execmode"
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
  filelist=`find $indatapath/*/*/$run/raw -iname "[0-9]*\.[0-9]*\.root"`
  run=`printf %09d $runnr`
else
  echo 1
  filelist=`cat $runnr`
  run=`basename $runnr | sed -e 's/\..*//g'`
fi

[[ -d $outdatapath/$run ]] || mkdir -p $outdatapath/$run
pushd $outdatapath/$run

for file in $filelist; do 

    chunk=`basename $file .root`;
    year=20${chunk:0:2}
    period=`echo $file | sed -e 's/.*\(LHC[0-9].[^\/]\)\/.*/\1/g'`
    echo $year $chunk;
    [[ -d $chunk ]] || mkdir $chunk

    ocdb="local://${ocdbpath}/${year}/OCDB"
    m4 -D ___OCDB___=$ocdb \
       -D ___FILENAME___=$file \
       -D ___NEVENTS___=$nevents \
       -D ___STARTEVENT___=$startevent \
       -D ___RECDETECTORS___="$detectors" \
       -D ___TRD_RECOPTIONS___="$rec_options" \
       ${scriptpath}/rec.C > $chunk/rec.C

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

    if [ "$runlocal" -eq 0 ]; then
      echo "#!/bin/sh
        #BSUB -o $chunk/batch.log
        #BSUB -q $queue
        #BSUB -J rec-$chunk
        $command" | bsub
  
      touch $chunk/.queued
    else
      echo "Executing locally..." 
      (
        eval "$command" > "$chunk/local.log" 2>&1
      )
    fi
  
    njobs=$(($njobs + 1));
done

popd
