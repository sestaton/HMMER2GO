package HMMER2GO::Run::HMMER;

use 5.012;
use Moo;
use namespace::autoclean;

# guide to ebi webservices: http://www.ebi.ac.uk/Tools/webservices/services/pfa/hmmer_hmmscan_rest

=head1 NAME

HMMER - Run HMMER3 and store results in table format for mapping GO terms

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    my $hmmer = HMMER2GO::Run::HMMER->new(   );

=cut

=head1 AUTHOR

S. Evan Staton, C<< <statonse at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests through the project site at 
L<https://github.com/sestaton/HMMER2GO/issues>. I will be notified,
and there will be a record of the issue. Alternatively, I can also be 
reached at the email address listed above to resolve any questions.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc HMMER2GO::Run::HMMER


=head1 LICENSE AND COPYRIGHT

Copyright 2014 S. Evan Staton.

This program is distributed under the MIT (X11) License:
L<http://www.opensource.org/licenses/mit-license.php>

=cut

1;
