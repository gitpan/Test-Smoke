#! /usr/bin/perl -w
use strict;

use Getopt::Long;
use File::Spec;
use Cwd;
use FindBin;
use lib File::Spec->catdir( $FindBin::Bin, 'lib' );
use Test::Smoke::Mailer;

use Test::Smoke;
use vars qw( $VERSION );
$VERSION = '0.007';

my %opt = (
    type    => undef,
    ddir    => '',
    to      => '', #'smokers-reports@perl.org',
    cc      => '',
    from    => '',
    mserver => '',
    v       => 0,

    config  => undef,
    help    => 0,
    man     => 0,
);

my $defaults = Test::Smoke::Mailer->config( 'all_defaults' );

my %valid_type = map { $_ => 1 } qw( mail mailx sendmail Mail::Sendmail );

=head1 NAME

mailrpt.pl - Send the smoke report by mail

=head1 SYNOPSIS

    $ ./mailrpt.pl -t mailx -d ../perl-current [--help | more options]

or

    $ ./mailrpt.pl -c smokecurrent_config

=head1 OPTIONS

Options depend on the B<type> option, exept for some.

=over 4

=item * B<Configuration file>

    -c | --config <configfile> Use the settings from the configfile

F<mailrpt.pl> can use the configuration file created by F<configsmoke.pl>.
Other options can override the settings from the configuration file.

=item * B<General options>

    -d | --ddir <directory>  Set the directory for the source-tree (cwd)
    --to <emailaddresses>    Comma separated list (smokers-reports@perl.org)
    --cc <emailaddresses>    Comma separated list
    -v | --verbose           Be verbose

    -t | --type <type>       mail mailx sendmail Mail::Sendmail [mandatory]

=item * B<options for> -t mail/mailx

no extra options

=item * B<options for> -t sendmail

    --from <address>

=item * B<options for> -t Mail::Sendmail

    --from <address>
    --mserver <smtpserver>  (localhost)

=back

=cut

GetOptions( \%opt,
    'type|t=s', 'ddir|d=s', 'to=s', 'cc=s', 'v|verbose+',

    'from=s', 'mserver=s',

    'help|h', 'man|m',

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
            if ( $option eq 'type' ) {
                $opt{type} ||= $conf->{mail_type};
            } elsif ( exists $conf->{ $option } ) {
                $opt{ $option } ||= $conf->{ $option }
            }
        }
    } else {
        warn "WARNING: Could not process '$opt{config}': " . 
             Test::Smoke->config_error . "\n";
    }
}

exists $valid_type{ $opt{type} } or do_pod2usage( verbose => 0 );

$opt{ddir} && -d $opt{ddir} or do_pod2usage( verbose => 0 );

my $mailer = Test::Smoke::Mailer->new( $opt{type} => \%opt );
$mailer->mail;

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

L<Test::Smoke::Mailer>, L<mkovz.pl>

=head1 COPYRIGHT

(c) 2002-2003, All rights reserved.

  * Abe Timmerman <abeltje@cpan.org>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

See:

=over 4

=item * http://www.perl.com/perl/misc/Artistic.html

=item * http://www.gnu.org/copyleft/gpl.html

=back

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut