#!/bin/bash

function show_help() {
  echo "GTU simulation script"
  echo "  Usage: `basename $0` [options] <inputdir>"
  echo "  Options:"
  echo "    -q <q>   Specify batch queue to submit to"
  echo "    -l        Run on local machine (useful for testing)"
  echo "    -o <o>    Specify output directory"
  echo "    -m <i>    Limit maximum number of jobs (=chunks) to submit to <i>"
  echo "    -n <i>    Process <i> events per chunk, starting from <s>"
  echo "    -s <i>    Specify start event <s>"
  echo "    -v <c>    Specify aliroot version to use (default: dev)"
  echo "    -h        Show this help"
}

#--------------------------------------------------------------------------------

alirootversion="dev"
nevents=10001
startevent=0
maxjobs=10
queue="norun"
inputdir=.

scriptpath=`dirname $(readlink -f $0)`
[[ -f ${scriptpath}/batch.sh ]] && source ${scriptpath}/batch.sh || exit -1

while getopts "hlq:m:Nn:o:s:v:" OPTION
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
    o)  outputdir=$OPTARG
        ;;
    s)  startevent=$OPTARG
        ;;
    v)  alirootversion=$OPTARG
        ;;
    ?)  show_help
        exit 1
        ;;
    esac
done
shift $(($OPTIND - 1))

[[ $# > 0 ]]  && inputdir=$(readlink -f $1 | sed -e 's/\/SAT//')

[[ x$outputdir == x ]] && outputdir=$inputdir

#--------------------------------------------------------------------------------
echo "#-------------------------------------------------------------------"
echo "#  RunNumber:        $runnr"
echo "#  Queue:            $queue"
echo "#  MaxJobs:          $maxjobs"
echo "#  AliRootVersion:   $alirootversion"
echo "#  Input Directory:  $inputdir"
echo "#  Output Directory: $outputdir"
echo "#    nevents: $nevents     startevent: $startevent"
echo "#-------------------------------------------------------------------"
#--------------------------------------------------------------------------------
run=`printf %09d $runnr`

# count jobs already submitted
njobs=0;
jobtype=gtusim

echo "searching for files now"
for file in `find $inputdir -iname "TRD.Tracklets.root"`; do
  echo $file

  inpath=$(dirname $file)
  outpath=$(perl -e "\$fi=\"$inpath\"; \$fi =~ s%$inputdir%$outputdir/%; print \"\$fi\";")

  # if max no of jobs not yet exceeded submit the job
  if [ $njobs -ge $maxjobs ]; then
    break;
  fi;

  # skip if we don't find the data
  [[ -e $inpath/galice.root ]] || continue;

  # skip if the job in queued or output is available
  [[ -e $outpath/.queued_${jobtype} ]] && continue;

  # echo "inpath  = $inpath"
  # echo "outpath = $outpath"

  mkdir -p $outpath

  for i in `find $inpath -name *.root`; do
    if [[ $i =~ "NewAliESDs.root" ]]; then
      ln -sf $i $outpath/AliESDs.root;
    elif [[ $i =~ "NewAliESDfriends.root" ]]; then
      ln -sf $i $outpath/AliESDfriends.root;
    else
      ln -sf $i $outpath;
    fi;
  done

  # prepare gtusim.C
  m4 \
      -D ___NEVENTS___=$nevents\
      $scriptpath/macros/gtusim.C.m4 > $outpath/gtusim.C

  # prepare run script
  m4 \
      -D ___SCRIPTPATH___=${scriptpath} \
      -D ___ALIROOT_VERSION___=${alirootversion} \
      -D ___WORKDIR___=${outpath} \
      ${scriptpath}/scripts/run${jobtype}.sh.m4 > ${outpath}/run${jobtype}.sh
  chmod u+x ${outpath}/run${jobtype}.sh

  if [ "x$queue" == "xnorun" ] ; then
      echo "not executing GTU simulation"

  elif [ "x$queue" == "xrunlocal" ] ; then
      echo "Executing locally..." 
      ( ${outpath}/run${jobtype}.sh > "${outpath}/${jobtype}.local.log" 2>&1 )

  else 
      submit ${jobtype} ${outdatapath}/${chunk} run${jobtype}.sh ${queue}

      touch $outpath/.queued_${jobtype}
  fi

  echo "#-------------------------------------------------------------------"
  njobs=$(($njobs + 1));
done
