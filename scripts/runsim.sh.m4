#!/bin/bash

date
. ___SCRIPTPATH___/alijkl ___ALIROOT_VERSION___
which aliroot
cd ___WORKDIR___ || exit -1
printenv > environment.log
aliroot -l -q -b ./sim.C
