#####################################################
declare -f module>  /dev/null;
hasMODULE=$?

if [ ${hasMODULE} -eq 0 ] ; then

      if [ -d /cvmfs/alice.gsi.de/modules ] ; then
          module use /cvmfs/alice.gsi.de/modules
          [ -d /hera/alice/jklein/sw/modules ] && module use --append /hera/alice/jklein/sw/modules
      elif [ -d /d/ali-data/modules ] ; then
          module use /d/ali-data/modules
      else
          echo "ERROR : No modules can be found !!!"
      fi
fi
##################################################### 

module load ALICE/$1
