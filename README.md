HMMER2GO
========

Annotate DNA sequences for Gene Ontology terms

**DEPENDENCIES**

EMBOSS and HMMER version 3+ must be installed to use HMMER2GO. See the installing dependencies wiki page for instructions how to install these programs.

**INSTALLATION**

Perl version 5.10 (or greater) must be installed to use HMMER2GO, and there are a couple of external modules required. If you have [cpanminus](http://search.cpan.org/~miyagawa/App-cpanminus-1.6935/lib/App/cpanminus.pm), installation can be done with a single command:

    cpanm git://github.com/sestaton/HMMER2GO.git

Alternatively, download the latest [release](https://github.com/sestaton/HMMER2GO/releases) and run the following command in the top directory:

    perl Makefile.PL

If any Perl dependencies are listed after running this command, install them through the CPAN shell (or any method you like). Then build and install the package.

    perl Makefile.PL
    make
    make test
    make install

**USAGE**

Starting with a file of DNA sequences, we first want to get the longest open reading frame (ORF) for each gene and translate those sequences.

    hmmer2go getorf -i genes.fasta -o genes_orfs.faa

Next, we search our ORFs for coding domains. 

    hmmer2go search -i genes_orfs.faa -d Pfam-A.hmm 

The above command will create three files: genes_orfs_hmmscan-pfamA.out, 
	                                   genes_orfs_hmmscan-pfamA.domtblout, 
 	                                   and genes_orfs_hmmscan-pfamA.tblout

We will now use the table of domain matches to map GO terms. To do this we first need to download the Pfam->Gene Ontology mappings. This can be done with a single command:

    hmmer2go fetch

The above command creates the file: pfam2go.

Now we can map the protein domain matches to GO terms.

    hmmer2go mapterms -i genes_orfs_hmmscan-pfamA.tblout -p pfam2go -o genes_orfs_hmmscan-pfamA_GO.tsv --map

This last command will create two output files: genes_orfs_hmmscan-pfamA_GO.tsv, 
                                                and genes_orfs_hmmscan-pfamA_GO_GOterm_mapping.tblout

The first output file is a tab-delimited table with a description of each domain, including the GO terms and the associated functions. The last file is a two column table with the sequence name in the first column and the GO terms associated with that sequence in the second column.

**DOCUMENTATION**

Each subcommand can be executed with no arguments to generate a help menu. Alternatively, you may specify help message explicitly. For example,

    hmmer2go help search

**ISSUES**

Report any issues at the HMMER2GO issue tracker: https://github.com/sestaton/HMMER2GO/issues

**ATTRIBUTION**

This project uses the [readfq](https://github.com/lh3/readfq) library written by Heng Li. The readfq code has been modified for error handling and to parse the comment line in the Casava header.

**LICENSE AND COPYRIGHT**

Copyright (C) 2014 S. Evan Staton

This program is distributed under the MIT (X11) License, which should be distributed with the package. 
If not, it can be found here: http://www.opensource.org/licenses/mit-license.php