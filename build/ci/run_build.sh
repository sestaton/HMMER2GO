#!/bin/bash

echo "Testing connection GO website"
wget ftp://ftp.geneontology.org/pub/go/external2go/pfam2go

wget http://eddylab.org/software/hmmer3/3.1b2/hmmer-3.1b2-linux-intel-x86_64.tar.gz
tar xzf hmmer-3.1b2-linux-intel-x86_64.tar.gz
sudo cp hmmer-3.1b2-linux-intel-x86_64/binaries/* /usr/bin
