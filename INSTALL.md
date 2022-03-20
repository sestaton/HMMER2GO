**DEPENDENCIES**

EMBOSS and HMMER version 3+ must be installed to use HMMER2GO. See the [installing dependencies](https://github.com/sestaton/HMMER2GO/wiki/Installing-dependencies) wiki page for instructions how to install these programs (or see below for Linux installation).

**INSTALLATION**

Perl must be installed to use HMMER2GO, and there are a couple of external modules required. Please download and install the latest [HMMER3](https://hmmer.org) executables manually on RHEL. The system versions available from the package manager are incompatible with the latest model formats but the packages are up-to-date on Ubuntu.

The installation can be done with the following command (note that this requires [git](http://git-scm.com/)):

For Ubuntu/Debian as the OS:

    apt-get install -y build-essential emboss hmmer zlib1g-dev libxml2-dev libexpat1-dev libssl-dev
    curl -L cpanmin.us | perl -  https://github.com/sestaton/HMMER2GO/archive/refs/tags/v0.18.2.tar.gz

For RHEL/Fedora:

    yum install -y EMBOSS zlib-devel libxml2-devel openssl-devel expat-devel
    curl -L cpanmin.us | perl -  https://github.com/sestaton/HMMER2GO/archive/refs/tags/v0.18.2.tar.gz

For MacOS, install the dependencies:

    brew install libxml2 zlib expat openssl
    brew tap brewsci/science
    brew install emboss

Then, install HMMER2GO as shown below. Additionally, you'll need to download the [HMMER3](https://hmmer.org) binaries for Mac and place them somewhere in your PATH.

Alternatively, download the latest [release](https://github.com/sestaton/HMMER2GO/releases) and run the following command in the top directory:

    perl Makefile.PL

If any Perl dependencies are listed after running this command, install them through the CPAN shell (or any method you like). Then build and install the package.

    perl Makefile.PL
    make
    make test
    make install