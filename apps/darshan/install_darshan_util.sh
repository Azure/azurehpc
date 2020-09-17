#!/bin/bash

spack install darshan-util%gcc@9.2.0

sudo yum install -y xauth

sudo yum install -y texlive
sudo yum install -y texlive-epstopdf
sudo yum install -y gnuplot
sudo yum install -y texlive-lastpage
sudo yum install -y texlive-subfigure
sudo yum install -y texlive-multirow
sudo yum install -y texlive-threeparttable
sudo yum install -y perl-Pod-LaTeX
sudo yum install -y perl-HTML-Parser
sudo yum install -y ghostscript

sudo yum install -y evince
