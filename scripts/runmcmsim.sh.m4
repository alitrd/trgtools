#!/bin/bash

date
. ___SCRIPTPATH___/alijkl ___ALIROOT_VERSION___
which aliroot
printenv > environment.log
cd ___WORKDIR___ && aliroot -l -q -b ./mcmsim.C
