#! /usr/bin/perl -w
use strict;
$| = 1;

# $Id: patchtree.pl 255 2003-07-21 10:52:24Z abeltje $
use vars qw( $VERSION );
$VERSION = '0.006';

use Cwd;
use File::Spec;
use FindBin;
use lib File::Spec->catdir( $FindBin::Bin, 'lib' );
use lib $FindBin::Bin;
use Test::Smoke;
use Test::Smoke::Patcher;

use Getopt::Long;
my %opt = (
    type    => 'multi',
    ddir    => undef,
    pfile   => undef,
    v       => undef,

    config  => undef,
    help    => 0,
    man     => 0,
);

my $defaults = Test::Smoke::Patcher->config( 'all_defaults' );

my %valid_type = map { $_ => 1 } qw( single multi );

=head1 NAME

patchtree.pl - Patch the sourcetree

=head1 SYNOPSIS

    $ ./patchtree.pl -f patchfile -d ../perl-current [--help | more options]

or

    $ ./patchtree.pl -c [smokecurrent_config]

=head1 OPTIONS

=over 4

=item * B<Configuration file>

    -c | --config <configfile> Use the settings from the configfile

F<patchtree.pl> can use the configuration file created by F<configsmoke.pl>.
Other options can override the settings from the configuration file.

=item * B<General options>

    -d | --ddir <directory>  Set the directory for the source-tree (cwd)
    -f | --pfile <patchfile> Set the resource containg patch info

    -v | --verbose <0..2>    Set verbose level
    -h | --help              Show help message (needs Pod::Usage)
    --man                    Show the perldoc  (needs Pod::Usage)

=back

=head1 DESCRIPTION

This is a small front-end for L<Test::Smoke::Patcher>.

=cut

GetOptions( \%opt,
    'pfile|f=s', 'ddir|d=s', 'v|verbose=i',

    'popts=s',

    'help|h', 'man',

    'config|c:s',
) or do_pod2usage( verbose => 1 );

$opt{man}  and do_pod2usage( verbose => 2, exitval => 0 );
$opt{help} and do_pod2usage( verbose => 1, exitval => 0 );

if ( defined $opt{config} ) {
    $opt{config} eq "" and $opt{config} = 'smokecurrent_config';
    read_config( $opt{config} ) or do {
        my $config_name = File::Spec->catfile( $FindBin::Bin, $opt{config} );
        read_config( $config_name );
    };

    unless ( Test::Smoke->config_error ) {
        foreach my $option ( keys %opt ) {
            next if defined $opt{ $option };
            if ( $option eq 'type' ) {
                $opt{type} ||= $conf->{patch_type};
            } elsif ( exists $conf->{ $option } ) {
                $opt{ $option } ||= $conf->{ $option }
            }
        }
    } else {
        warn "WARNING: Could not process '$opt{config}': " . 
             Test::Smoke->config_error . "\n";
    }
}

foreach( keys %$defaults ) {
    next if defined $opt{ $_ };
    $opt{ $_ } = defined $conf->{ $_ } ? $conf->{ $_ } : $defaults->{ $_ };
}

exists $valid_type{ $opt{type} } or do_pod2usage( verbose => 0 );

$opt{ddir} && -d $opt{ddir} or do_pod2usage( verbose => 0 );
$opt{pfile} && -f $opt{pfile} or do_pod2usage( verbose => 0 );

if ( $^O eq 'MSWin32' ) {
    Test::Smoke::Patcher->config( flags => TRY_REGEN_HEADERS );
}
my $patcher = Test::Smoke::Patcher->new( $opt{type} => \%opt );
eval{ $patcher->patch };

sub do_pod2usage {
    eval { require Pod::Usage };
    if ( $@ ) {
        print <<EO_MSG;
Usage: $0 -t <type> -d <directory> [options]

Use 'perldoc $0' for the documentation.
Please install 'Pod::Usage' for easy access to the docs.

EO_MSG
        my %p2u_opt = @_;
        exit( exists $p2u_opt{exitval} ? $p2u_opt{exitval} : 1 );
    } else {
        Pod::Usage::pod2usage( @_ );
    }
}

=head1 SEE ALSO

L<Test::Smoke::Patcher>

=head1 COPYRIGHT

(c) 2002-2003, All rights reserved.

  * Abe Timmerman <abeltje@cpan.org>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

See:

=over 4

item * L<http://www.perl.com/perl/misc/Artistic.html>

item * L<http://www.gnu.org/copyleft/gpl.html>

=back

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut