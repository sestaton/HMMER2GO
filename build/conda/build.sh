#!/bin/bash

#perl ${PREFIX}/bin/cpanm App::Cmd
#perl Makefile.PL
#make
# make test
#make install
# PERL_MM_USE_DEFAULT=1  -> automatically answer "yes" on config questions
PERL_MM_USE_DEFAULT=1 cpan App::cpanminus
PERL5LIB="" PERL_LOCAL_LIB_ROOT="" PERL_MM_OPT="" PERL_MB_OPT="" perl ${BUILD_PREFIX}/bin/cpanm --installdeps .
perl Makefile.PL INSTALLDIRS=site
make
make install
