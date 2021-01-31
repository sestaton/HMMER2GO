HMMER2GO
========

Annotate DNA sequences for Gene Ontology terms

[![Build Status](https://travis-ci.org/sestaton/HMMER2GO.svg?branch=master)](https://travis-ci.org/sestaton/HMMER2GO) [![Coverage Status](https://coveralls.io/repos/github/sestaton/HMMER2GO/badge.svg?branch=master)](https://coveralls.io/github/sestaton/HMMER2GO?branch=master)

### What is HMMER2GO?

HMMER2GO is a command line application to map DNA sequences, typically transcripts, to [Gene Ontology](http://geneontology.org/) based on the similarity of the query sequences to curated HMM models for protein families represented in [Pfam](http://pfam.xfam.org/).

These GO term mappings allow you to make inferences about the function of the gene products, or changes in function in the case of expression studies. The GAF mapping file that is produced can be used with Ontologizer or other tools, to visualize a graph of the term relationships along with their signifcance values.

**INSTALLATION**

It is recommended to use [Docker](https://www.docker.com), as shown below:

    docker run -it --name hmmer2go-con -v $(pwd)/db:/db:Z sestaton/hmmer2go

That will create a container called "hmmer2go-con" and start an interactive shell. The above assumes you have a directory called db in the working directory that contains your database files (Pfam HMM file that is formatted), and the input sequences. To run the full analysis, change to the mounted directory with cd db in your container and run the commands shown below.

Alternatively, you can follow the steps in the [INSTALL](https://github.com/sestaton/HMMER2GO/blob/master/INSTALL.md) file and install HMMER2GO on any Mac or Linux, and likely Windows (though I have not tested yet, advice is welcome).

Please see the wiki [Demonstration](https://github.com/sestaton/HMMER2GO/wiki/Demonstraton) page for full working example and demo script that will download and run HMMER2GO. This page also contains a brief description of how to begin analyzing the results.

**BRIEF USAGE**

Starting with a file of DNA sequences, we first want to get the longest open reading frame (ORF) for each gene and translate those sequences.

    hmmer2go getorf -i genes.fasta -o genes_orfs.faa

Next, we search our ORFs for coding domains. 

    hmmer2go run -i genes_orfs.faa -d Pfam-A.hmm -o genes_orf_Pfam-A.tblout

Now we can map the protein domain matches to GO terms.

    hmmer2go mapterms -i genes_orfs_Pfam-A.tblout -o genes_orfs_Pfam-A_GO.tsv --map

If we want to perform a statistical analysis on the GO mappings, it may be necessary to create a GAF file.

    hmmer2go map2gaf -i genes_orfs_Pfam-A_GO_GOterm_mapping.tsv -o genes_orfs_Pfam-A_GO_GOterm_mapping.gaf -s 'Helianthus annuus'

For a full explanation of these commands, see the [HMMER2GO wiki](https://github.com/sestaton/HMMER2GO/wiki). In particular, see the [tutorial](https://github.com/sestaton/HMMER2GO/wiki/Tutorial) page for a walk-through of all the commands. There is also an example script on the [demonstration](https://github.com/sestaton/HMMER2GO/wiki/Demonstraton) page to fetch data for _Arabidopsis thaliana_ and run the full analysis.

**DOCUMENTATION**

Each subcommand can be executed with no arguments to generate a help menu. Alternatively, you may specify help message explicitly. For example,

    hmmer2go help run

More information about each command is available by accessing the full documentation at the command line. For example,

    hmmer2go run --man

Also, the [HMMER2GO wiki](https://github.com/sestaton/HMMER2GO/wiki) is a source of online documentation.

**ISSUES**

Report any issues at the HMMER2GO issue tracker: https://github.com/sestaton/HMMER2GO/issues

**LICENSE AND COPYRIGHT**

Copyright (C) 2014-2020 S. Evan Staton

This program is distributed under the MIT (X11) License, which should be distributed with the package. 
If not, it can be found here: http://www.opensource.org/licenses/mit-license.php