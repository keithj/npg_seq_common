#!/bin/bash

set -e -x

export TEST_AUTHOR=1
unset PERL5LIB

. ~/miniconda/etc/profile.d/conda.sh
conda activate travis

cpanm --local-lib=~/perl5 local::lib && eval $(perl -I ~/perl5/lib/perl5/ -Mlocal::lib)

perl Build.PL
./Build test
