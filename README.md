HMMER2GO
========

Annotate DNA sequences for Gene Ontology terms

[![Build Status](https://travis-ci.org/sestaton/HMMER2GO.svg?branch=master)](https://travis-ci.org/sestaton/HMMER2GO)

**DEPENDENCIES**

EMBOSS and HMMER version 3+ must be installed to use HMMER2GO. See the [installing dependencies](https://github.com/sestaton/HMMER2GO/wiki/Installing-dependencies) wiki page for instructions how to install these programs.

**INSTALLATION**

Perl version 5.12 (or greater) must be installed to use HMMER2GO, and there are a couple of external modules required. If you have [cpanminus](https://metacpan.org/pod/App::cpanminus), installation can be done with a single command:

    cpanm git://github.com/sestaton/HMMER2GO.git

Alternatively, download the latest [release](https://github.com/sestaton/HMMER2GO/releases) and run the following command in the top directory:

    perl Makefile.PL

If any Perl dependencies are listed after running this command, install them through the CPAN shell (or any method you like). Then build and install the package.

    perl Makefile.PL
    make
    make test
    make install

**BRIEF USAGE**

Starting with a file of DNA sequences, we first want to get the longest open reading frame (ORF) for each gene and translate those sequences.

    hmmer2go getorf -i genes.fasta -o genes_orfs.faa

Next, we search our ORFs for coding domains. 

    hmmer2go search -i genes_orfs.faa -d Pfam-A.hmm 

To map the domain matches to GO terms we first need to download the Pfam to Gene Ontology mappings. This can be done with a single command:

    hmmer2go fetch

The above command creates the file: pfam2go.

Now we can map the protein domain matches to GO terms.

    hmmer2go mapterms -i genes_orfs_Pfam-A.tblout -p pfam2go -o genes_orfs_Pfam-A_GO.tsv --map

If we want to perform a statistical analysis on the GO mappings, it may be necessary to create a GAF file.

    hmmer2go map2gaf -i genes_orfs_Pfam-A_GO_GOterm_mapping.tsv -o genes_orfs_Pfam-A_GO_GOterm_mapping.gaf -s 'Helianthus annuus'

For a full explanation of these commands, see the [HMMER2GO wiki](https://github.com/sestaton/HMMER2GO/wiki). In particular, see the [tutorial](https://github.com/sestaton/HMMER2GO/wiki/Tutorial) page for a walk-through of all the commands.

**DOCUMENTATION**

Each subcommand can be executed with no arguments to generate a help menu. Alternatively, you may specify help message explicitly. For example,

    hmmer2go help search

More information about each command is available by accessing the full documentation at the command line. For example,

    hmmer2go getorf --man

Also, the [HMMER2GO wiki](https://github.com/sestaton/HMMER2GO/wiki) is a source of online documentation.

**ISSUES**

Report any issues at the HMMER2GO issue tracker: https://github.com/sestaton/HMMER2GO/issues

**ATTRIBUTION**

This project uses the [readfq](https://github.com/lh3/readfq) library written by Heng Li. The readfq code has been modified for error handling and to parse the comment line in the Casava header.

**LICENSE AND COPYRIGHT**

Copyright (C) 2014 S. Evan Staton

This program is distributed under the MIT (X11) License, which should be distributed with the package. 
If not, it can be found here: http://www.opensource.org/licenses/mit-license.php