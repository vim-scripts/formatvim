#!/bin/zsh
: ${TESTDIR:=/tmp/frawor-profile}
if [[ -z $RTP ]] ; then
    RTP=$TESTDIR
else
    RTP+=,$TESTDIR
fi
./gentestdir.zsh $TESTDIR $1
(( $# )) && shift
typeset -x TESTDIR RTP
pushd $TESTDIR
vim -u <(<<< 'let &rtp=$RTP') -N -U NONE -i NONE \
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
