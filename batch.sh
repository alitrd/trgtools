#!/bin/bash

function farm() {
    ip=$(host `hostname` | sed -e 's/.* has address \([0-9]*.[0-9]*.[0-9]*.[0-9]*\)/\1/')
    host ica.hpc   | grep $ip > /dev/null 2>&1 && echo "ica"
    host pro.hpc   | grep $ip > /dev/null 2>&1 && echo "pro"
    host lxlenny64 | grep $ip > /dev/null 2>&1 && echo "lenny64"
}

function submit_sge() {
    cat > $2/$1.job <<EOF
#$ -o $2/$1.batch.log
#$ -e $2/$1.batch.err
#$ -l h_rss=4G
#$ -wd $2
./$3
EOF
    qsub < $2/$1.job
}

function submit_lsf() {
    echo "#!/bin/sh
        #BSUB -o $2/$1.batch.log
        #BSUB -e $2/$1.batch.err
        #BSUB -q $4
        #BSUB -J $1-$2
        $2/$3" | tee $2/$1.job
    bsub < $2/$1.job
}

function submit_condor() {
    cat > $2/$1.job <<EOF
universe=vanilla
getenv=false
output=$2/$1.batch.out
error=$2/$1.batch.err
log=$2/$1.batch.log
Executable=$2/$3.sh
queue
EOF
    cat $2/$1.job
    #condor_submit $2/$1.job
}

function submit() {
    # parameters:
    # 1: name
    # 2: workdir
    # 3: executable
    # 4: batch queue

    batch_system=lsf

    farm=`farm`
    echo $farm
    [[ $farm =~ pro|ica ]] && batch_system=sge
    echo $@
    submit_${batch_system} $1 $2 $3 $4
}
