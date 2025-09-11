HMMER2GO
========

Annotate DNA sequences for Gene Ontology terms

Build Status|Version
---|---
[![CI](https://github.com/sestaton/HMMER2GO/actions/workflows/main.yml/badge.svg)](https://github.com/sestaton/HMMER2GO/actions/workflows/main.yml) | [![GitHub version](https://badge.fury.io/gh/sestaton%2FHMMER2GO.svg)](https://badge.fury.io/gh/sestaton%2FMMER2GO)

### What is HMMER2GO?

HMMER2GO is a command line application to map DNA sequences, typically transcripts, to [Gene Ontology](http://geneontology.org/) based on the similarity of the query sequences to curated HMM models for protein families represented in Pfam (now available through [InterPro](https://www.ebi.ac.uk/interpro/)).

These GO term mappings allow you to make inferences about the function of the gene products, or changes in function in the case of expression studies. The GAF mapping file that is produced can be used with Ontologizer or other tools, to visualize a graph of the term relationships along with their signifcance values.

**INSTALLATION**

It is recommended to use [Docker](https://www.docker.com) for easy installation and usage. Here are examples of running HMMER2GO commands with Docker:

    # Get help for a specific command
    docker run --rm sestaton/hmmer2go help getorf
    
    # Run getorf to extract ORFs from DNA sequences
    docker run --rm -v $(pwd):/data -w /data sestaton/hmmer2go getorf -i genes.fasta -o genes_orfs.faa
    
    # Run domain search against Pfam database
    docker run --rm -v $(pwd):/data -w /data sestaton/hmmer2go run -i genes_orfs.faa -d Pfam-A.hmm -o genes_orf_Pfam-A.tblout
    
    # Map Pfam domains to GO terms
    docker run --rm -v $(pwd):/data -w /data sestaton/hmmer2go mapterms -i genes_orfs_Pfam-A.tblout -o genes_orfs_Pfam-A_GO.tsv --map

The `--rm` flag automatically removes the container after execution. The `-v $(pwd):/data` mounts your current directory to `/data` inside the container, and `-w /data` sets the working directory so HMMER2GO can access your local files with their simple filenames.

**Alternative Installation**

You can also follow the steps in the [INSTALL](https://github.com/sestaton/HMMER2GO/blob/master/INSTALL.md) file to install HMMER2GO directly on Mac or Linux systems.

Please see the wiki [Demonstration](https://github.com/sestaton/HMMER2GO/wiki/Demonstraton) page for full working example and demo script that will download and run HMMER2GO. This page also contains a brief description of how to begin analyzing the results.

**BRIEF USAGE**

### Full Workflow Example

Starting with a file of DNA sequences, we first want to get the longest open reading frame (ORF) for each gene and translate those sequences.

    hmmer2go getorf -i genes.fasta -o genes_orfs.faa

Next, we search our ORFs for coding domains against the full Pfam database.

    hmmer2go run -i genes_orfs.faa -d Pfam-A.hmm -o genes_orf_Pfam-A.tblout

Now we can map the protein domain matches to GO terms.

    hmmer2go mapterms -i genes_orfs_Pfam-A.tblout -o genes_orfs_Pfam-A_GO.tsv --map

If we want to perform a statistical analysis on the GO mappings, it may be necessary to create a GAF file.

    hmmer2go map2gaf -i genes_orfs_Pfam-A_GO_GOterm_mapping.tsv -o genes_orfs_Pfam-A_GO_GOterm_mapping.gaf -s 'Helianthus annuus'

### Custom Database Creation

You can also create custom HMM databases for specific protein families using keyword searches:

    # Search for MADS-box transcription factors and create a custom database
    hmmer2go pfamsearch -t "mads,mads-box" -o mads_pfam_results.txt -d
    
    # Use the custom database for faster, targeted searches
    hmmer2go run -i genes_orfs.faa -d mads+mads-box_hmms/mads+mads-box.hmm -o genes_orf_mads.tblout

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

Copyright (C) 2014-2025 S. Evan Staton

This program is distributed under the MIT (X11) License, which should be distributed with the package. 
If not, it can be found here: http://www.opensource.org/licenses/mit-license.php
