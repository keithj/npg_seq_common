#!/bin/bash

set -e -x

# The default build branch for all repositories. This defaults to
# TRAVIS_BRANCH unless set in the Travis build environment.
WTSI_NPG_BUILD_BRANCH=${WTSI_NPG_BUILD_BRANCH:=$TRAVIS_BRANCH}

sudo apt-get install libgd2-xpm-dev # for npg_tracking
cpanm --quiet --notest LWP::Protocol::https

wget --quiet https://repo.anaconda.com/miniconda/Miniconda3-4.6.14-Linux-x86_64.sh -O ~/miniconda.sh

/bin/bash ~/miniconda.sh -b -p ~/miniconda
~/miniconda/bin/conda clean -tipsy
. ~/miniconda/etc/profile.d/conda.sh

echo ". ~/miniconda/etc/profile.d/conda.sh" >> ~/.bashrc
echo "conda activate travis" >> ~/.bashrc

conda config --set auto_update_conda False
conda config --add channels https://dnap.cog.sanger.ac.uk/npg/conda/devel/generic/

conda create -y -n travis
conda activate travis

conda install -y blat
conda install -y bowtie
conda install -y bowtie2
conda install -y bwa
conda install -y samtools
conda install -y picard
conda install -y biobambam2
conda install -y star
conda install -y minimap2
conda install -y hisat2

# WTSI NPG Perl repo dependencies
repos="perl-dnap-utilities npg_tracking"

for repo in $repos
do
  cd /tmp
  # Always clone master when using depth 1 to get current tag
  git clone --branch master --depth 1 "${WTSI_NPG_GITHUB_URL}/${repo}.git" "${repo}.git"
  cd /tmp/${repo}.git
  # Shift off master to appropriate branch (if possible)
  git ls-remote --heads --exit-code origin ${WTSI_NPG_BUILD_BRANCH} && git pull origin ${WTSI_NPG_BUILD_BRANCH} && echo "Switched to branch ${WTSI_NPG_BUILD_BRANCH}"
  cpanm --quiet --notest --installdeps . || find /home/travis/.cpanm/work -cmin -1 -name '*.log' -exec tail -n 20 {} \;
  perl Build.PL
  ./Build
  ./Build install
done
