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

alirootversion="dev"
nevents=10001
startevent=0
maxjobs=10
#queue=alice-t3_2h
queue=norun
trklconfig=real-notc
inputdir=.


scriptpath=`dirname $(readlink -f $0)`

echo $scriptpath

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

[[ $# > 0 ]]  && inputdir=$(readlink -f $1)

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
    [[ -e $outpath/.queued ]] && continue;


    echo "inpath  = $inpath"
    echo "outpath = $outpath"

    mkdir -p $outpath

    for i in galice.root TRD.Digits.root AliESDfriends.root AliESDs.root ; do
	#cp $inpath/$i $outpath;
	ln -sf $inpath/$i $outpath;
    done

    #rm $outpath/TRD.Digits.root
    #cp  $inpath/TRD.Tracklets.root $outpath

    m4 \
	-D ___TRACKLET_CONFIG___=$trklconfig\
	$scriptpath/mcmsim.C.m4 > $outpath/mcmsim.C



    echo $queue;

    if [ "x$queue" == "xnorun" ] ; then

	echo "not executing MCM simulator"

    elif [ "x$queue" == "xrunlocal" ] ; then


	. $scriptpath/alijkl $alirootversion
	pushd $outpath
	#printenv

	ls -l $inpath

	aliroot -b -q -l mcmsim.C
	popd

    else 

	echo "#!/bin/sh
          #BSUB -o $outpath/mcmsim.batch.log
          #BSUB -q $queue
          . $(dirname $0)/alijkl $alirootversion
          cd $outpath
          printenv > mcmsim.environment.log
          aliroot -l -q -b mcmsim.C" | bsub
  
	touch $outpath/.queued

    fi
  
    echo "#-------------------------------------------------------------------"
    njobs=$(($njobs + 1));
done


