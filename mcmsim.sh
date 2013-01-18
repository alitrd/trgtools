#!/bin/bash

function show_help() {
  echo "MCM simulation script"
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
scriptpath=`dirname $(readlink -f $0)`

[[ -f ${scriptpath}/batch.sh ]] && source ${scriptpath}/batch.sh || exit -1

farm=`farm`

alirootversion="dev"
nevents=10001
startevent=0
maxjobs=10
#queue=alice-t3_2h
queue=norun
trklconfig=real-notc
inputdir=.

while getopts "c:hlq:m:Nn:o:s:v:" OPTION
do 
  case $OPTION in
    h)  show_help
        exit 0
        ;; 
    c)  trklconfig=$OPTARG
        ;;
    q)  queue=$OPTARG
        ;;
    l)  queue="runlocal"
        ;;
    m)  maxjobs=$OPTARG
        ;;
    n)  nevents=$OPTARG
        ;;
    N)  queue="norun"
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

#sleep 2;


# count jobs already submitted
njobs=0;
jobtype=mcmsim

for file in `find $inputdir -iname "TRD.Digits.root"`; do

    inpath=$(dirname $file)
    outpath=$(perl -e "\$fi=\"$inpath\"; \$fi =~ s%$inputdir%$outputdir/%; print \"\$fi\";")

    # if max no of jobs not yet exceeded submit the job
    if [ $njobs -ge $maxjobs ]; then
	    break;
    fi;

    # skip if we don't find the data
    [[ -e $inpath/galice.root ]] || continue;
    [[ -e $inpath/TRD.Digits.root ]] || continue;

    # skip if the job in queued or output is available
    [[ -e $outpath/.queued_${jobtype} ]] && continue;

    echo "inpath  = $inpath"
    echo "outpath = $outpath"

    mkdir -p $outpath

    for i in `find $inpath -name *.root`; do
	#cp $inpath/$i $outpath;
	ln -sf $i $outpath;
    done

    # copy tracklets instead of symlinking
    rm -f $outpath/TRD.Tracklets.root
    cp  $inpath/TRD.Tracklets.root $outpath

    # prepare mcmsim.C
    m4 \
	-D ___TRACKLET_CONFIG___=$trklconfig\
	-D ___NEVENTS___=$nevents\
	$scriptpath/macros/mcmsim.C.m4 > $outpath/mcmsim.C
    cp *.datx $outpath/

    # prepare run script
    m4 \
	-D ___SCRIPTPATH___=${scriptpath} \
	-D ___ALIROOT_VERSION___=${alirootversion} \
	-D ___WORKDIR___=${outpath} \
	${scriptpath}/scripts/run${jobtype}.sh.m4 > ${outpath}/run${jobtype}.sh
    chmod u+x $outpath/run${jobtype}.sh

    # copy the script to setup the environment
    cp ${scriptpath}/alisetup.${farm} ${outpath}/alisetup

    if [ "x$queue" == "xnorun" ] ; then
	echo "not executing MCM simulator"

    elif [ "x$queue" == "xrunlocal" ] ; then
	echo "Executing locally..." 
	( ${outpath}/run${jobtype}.sh > "${outpath}/${jobtype}.local.log" 2>&1 )

    else 
	submit ${jobtype} ${outpath}/${chunk} run${jobtype}.sh ${queue}

	touch $outpath/.queued_${jobtype}
    fi
  
    echo "#-------------------------------------------------------------------"
    njobs=$(($njobs + 1));
done
