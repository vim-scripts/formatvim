#!/bin/zsh
: ${TESTDIR:=/tmp/frawor-profile}
./gentestdir.zsh $TESTDIR $1
(( $# )) && shift
typeset -x TESTDIR
pushd $TESTDIR
vim -u <(<<< 'set nocompatible rtp=$TESTDIR') -U NONE \
    --startuptime starttime.dat \
    --cmd 'profile start profile.dat' \
    --cmd 'profile func *' \
    --cmd 'profile file *' \
    $@ \
    -c 'profile pause' \
    -c 'qa!'
popd
cp $TESTDIR/profile.dat .
cp $TESTDIR/starttime.dat .
