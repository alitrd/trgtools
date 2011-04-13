#!/bin/bash

function show_help() {
  echo "HELP!"
}

#--------------------------------------------------------------------------------

alirootversion="dev"
datapath="/lustre/alice/alien/alice/data"
detectors="ITS TPC TRD TOF"
rec_options="tp,tw,dc"
nevents=10001
startevent=0
maxjobs=10
queue=alice-t3_2h

while getopts "hq:m:n:s:d:v:" OPTION
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
    d)  datapath=$OPTARG
        ;;
    v)  alirootversion=$OPTARG
        ;;
    ?)  show_help
        exit 1
        ;;
    esac
done
shift $(($OPTIND - 1))

runnr=$1

#--------------------------------------------------------------------------------
echo "#-------------------------------------------------------------------"
echo "#  RunNumber:      $runnr"
echo "#  Queue:          $queue"
echo "#  MaxJobs:        $maxjobs"
echo "#  Datapath:       $datapath"
echo "#  AliRootVersion: $alirootversion"
echo "#    nevents: $nevents     startevent: $startevent"
echo "#-------------------------------------------------------------------"
#--------------------------------------------------------------------------------
run=`printf %09d $runnr`

echo "Runnumber: $runnr"
echo "Max no. of jobs to be submitted: $maxjobs"
sleep 2;

# count jobs already submitted
njobs=0;

[[ -d $run ]] || mkdir -p $run
pushd $run

for file in `find $datapath/*/*/$run/raw -iname "*.*.root"`; do

    chunk=`basename $file .root`;
    year=20${chunk:0:2}
    period=`echo $file | sed -e 's/.*\(LHC[0-9].[^\/]\)\/.*/\1/g'`
    echo $year $chunk;
    [[ -d $chunk ]] || mkdir $chunk

    ocdb="local://${datapath}/${year}/OCDB"
    m4 -D ___OCDB___=$ocdb \
       -D ___FILENAME___=$file \
       -D ___NEVENTS___=$nevents \
       -D ___STARTEVENT___=$startevent \
       -D ___RECDETECTORS___="$detectors" \
       -D ___TRD_RECOPTIONS___="$rec_options" \
       ../rec.C > $chunk/rec.C

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

    echo "#!/bin/sh
      #BSUB -o $chunk/batch.log
      #BSUB -q $queue
      #BSUB -J rec-$chunk
      . alijkl $alirootversion
      cd $chunk
      printenv > environment.log
      aliroot -l -q -b ./rec.C" | bsub
  
    touch $chunk/.queued
  
    njobs=$(($njobs + 1));
done

popd

