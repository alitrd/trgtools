#!/bin/bash

dirname="src"
if [ x"$1" !=  x"" ]; then
    dirname=$1
fi;

git clone ssh://lx-pool.gsi.de/d/alice04/jkl/repo/alir ${dirname}

pushd ${dirname}

git config --add remote.origin.fetch "+refs/remotes/git-svn:refs/remotes/git-svn"
git svn init https://alisoft.cern.ch/AliRoot/trunk

git checkout -b jet-embedding origin/jet-embedding

git fetch

popd
