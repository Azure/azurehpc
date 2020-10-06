#!/bin/bash
SHARED_APP=${SHARED_APP:-/apps}
module use ${SHARED_APP}/modulefiles
module load spack/spack
source $SPACK_SETUP_ENV

spack install darshan-util%gcc@9.2.0

sudo yum install -y python3 xauth texlive texlive-epstopdf gnuplot texlive-lastpage texlive-subfigure texlive-multirow texlive-threeparttable perl-Pod-LaTeX perl-HTML-Parser ghostscript evince
