#!/bin/zsh
emulate -L zsh
: ${TESTDIR:=/tmp/frawor-depsgraph}
./gentestdir.zsh $TESTDIR $1
(( $# )) && shift
typeset -x TESTDIR
pushd $TESTDIR
vim -u <(<<< 'set nocompatible rtp=$TESTDIR') -U NONE \
    $@ \
    -c 'source tools/depstodot.vim' \
    -c 'call g:dtd.write("deps.dot")' \
    -c 'qa!'
popd
mv $TESTDIR/deps.dot .
dot -Tpng deps.dot -o deps.png
