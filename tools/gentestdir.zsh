#!/bin/zsh
emulate -L zsh
typeset -xr TESTDIR=$1
shift
test -d $TESTDIR || mkdir -p $TESTDIR
local -r REV=${1:-.}
(( $# )) && shift
if [[ $REV == '.' ]] ; then
    hg locate -0 | xargs -0 tar c -C $(hg root) | (cd $TESTDIR && tar x)
else
    hg archive -r $REV $TESTDIR
fi
