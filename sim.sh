#!/bin/bash

function show_help() {
  echo "Simulation script"
  echo "  Usage: `basename $0` [options]"
  echo "  Options:"
  echo "    -q <q>    Specify batch queue to submit to"
  echo "    -l        Run on local machine (useful for testing)"
  echo "    -o <o>    Specify output directory (default: $def_outdatapath)"
  echo "    -b <p>    Specify OCDB base path (default: $def_indatapath)"
  echo "                [Normally automatically derived]"
  echo "    -m <i>    Limit maximum number of jobs (=chunks) to submit to <i>"
  echo "    -n <i>    Process <i> events per chunk, starting from <s>"
  echo "    -t <type> process to simulate, e.g. kPythia6Jets104_125 (default: $def_simtype)"
  echo "    -v <c>    Specify aliroot version to use (default: dev)"
  echo "    -h        Show this help"
}

#--------------------------------------------------------------------------------
def_outdatapath="/tmp/test"
def_simtype="kPythia6"
def_bfield="b5n";

outdatapath=$def_outdatapath
scriptpath=`dirname $(readlink -f $0)`
ocdbpath=$indatapath
runlocal=0

alirootversion="dev"
simtype=$def_simtype
bfield=$def_bfield
nevents=100
maxjobs=10
ocdbother=0
queue=alice-t3_2h

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
echo "#    nevents: $nevents"
echo "#-------------------------------------------------------------------"
#--------------------------------------------------------------------------------

echo "Max no. of jobs to be submitted: $maxjobs"
sleep 2;

# count jobs already submitted
ijob=-1;
njobs=0;

[[ -d $outdatapath ]] || mkdir -p $outdatapath
pushd $outdatapath


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
    [[ -e $chunk/.queued_sim ]] && continue;

    mkdir -p $chunk

    if [ "$ocdbother" -eq 1 ]; then
      ocdb=${ocdbpath}
    else
      ocdb="local://${ocdbpath}/${year}/OCDB"
    fi

    m4 -D ___OCDB___=$ocdb \
       -D ___NEVENTS___=$nevents \
       ${scriptpath}/macros/sim.C.m4 > $chunk/sim.C

    m4 -D ___SIMTYPE___=$simtype \
       -D ___SCALEB___=$scalebfield \
       ${scriptpath}/macros/Config.C.m4 > $chunk/Config.C

    mkdir $chunk/trapcfg
    find ${scriptpath}/trapcfg -regex '.*.r[0-9]*' -exec cp {} $chunk/trapcfg/ \; ;

    command=". ${scriptpath}/alijkl $alirootversion; cd $chunk; printenv > environment.log; aliroot -l -q -b ./sim.C;"

    if [ "x$queue" == "xrunlocal" ]; then
      echo "Executing locally..." 
      (
        eval "$command" > "$chunk/sim.local.log" 2>&1
      )

    elif [ "x$queue" == "xnorun" ]; then
      echo "Not running simulation..."

    else
      echo "#!/bin/sh
        #BSUB -o $chunk/sim.batch.log
        #BSUB -e $chunk/sim.batch.err
        #BSUB -q $queue
        #BSUB -J sim-$chunk
        $command" | bsub
  
      touch $chunk/.queued_sim
    fi
  
    njobs=$(($njobs + 1));
done

popd
