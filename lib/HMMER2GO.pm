package HMMER2GO;
 
use App::Cmd::Setup -app;

=head1 NAME

HMMER2GO - Annotate DNA sequences for Gene Ontology terms

=head1 VERSION

Version 0.06

=cut

our $VERSION = '0.06';

sub global_opt_spec {
    [ 'man|m' => "Get the manual entry for a command" ];
}

=head1 AUTHOR

S. Evan Staton, C<< <statonse at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests through the project site at 
L<https://github.com/sestaton/HMMER2GO/issues>. I will be notified,
and there will be a record of the issue. Alternatively, I can also be 
reached at the email address listed above to resolve any questions.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc HMMER2GO


=head1 LICENSE AND COPYRIGHT

Copyright (C) 2014 S. Evan Staton

This program is distributed under the MIT (X11) License, which should be distributed with the package. 
If not, it can be found here: L<http://www.opensource.org/licenses/mit-license.php>

=cut

1;
