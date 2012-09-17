#!/bin/bash

date
#. ___SCRIPTPATH___/alijkl ___ALIROOT_VERSION___
cd ___WORKDIR___ || exit - 1
. alisetup ___ALIROOT_VERSION___
which aliroot
printenv > environment.log
aliroot -l -q -b gtusim.C
