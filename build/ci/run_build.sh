#!/bin/bash

#echo "Testing connection to GO website"
#wget ftp://ftp.geneontology.org/pub/go/external2go/pfam2go

wget http://eddylab.org/software/hmmer3/3.1b2/hmmer-3.1b2-linux-intel-x86_64.tar.gz
tar xzf hmmer-3.1b2-linux-intel-x86_64.tar.gz
sudo cp hmmer-3.1b2-linux-intel-x86_64/binaries/* /usr/bin

cd t/test_data
echo "Fetching GO mapping files"
#wget ftp://ftp.geneontology.org/pub/go/external2go/pfam2go
#wget ftp://ftp.geneontology.org/pub/go/doc/GO.terms_alt_ids

curl --verbose --progress-bar --ipv4 --connect-timeout 8 \
     --max-time 120 --retry 128 --ftp-ssl --disable-epsv --ftp-pasv \
     -u "anonymous:anonymous@foo.com" ftp://ftp.geneontology.org/pub/go/external2go/pfam2go \
     --output pfam2go

#curl --verbose --progress-bar --ipv4 --connect-timeout 8 \
#     --max-time 120 --retry 128 http://purl.obolibrary.org/obo/go.obo \
#     --output go.obo
wget -O go.obo http://purl.obolibrary.org/obo/go.obo

