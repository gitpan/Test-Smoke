#! /usr/bin/perl -w
use strict;

# $Id: smoker.t 246 2003-07-20 12:31:58Z abeltje $
use File::Spec;

use Test::More 'no_plan';
use_ok( 'Test::Smoke::Smoker' );

{
    my %config = (
        v => 0,
        ddir => 'perl-current',
        defaultenv => 1,
    );

    local *LOG;
    open LOG, "> " . File::Spec->devnull;

    my $smoker = Test::Smoke::Smoker->new( \*LOG, %config );
    isa_ok( $smoker, 'Test::Smoke::Smoker' );

    my $ref = mkargs( \%config, 
                      Test::Smoke::Smoker->config( 'all_defaults' ) );
    $ref->{logfh} = \*LOG;

    is_deeply( $smoker, $ref, "Check arguments" );   

    close LOG;
}

sub mkargs {
    my( $set, $default ) = @_;

    my %mkargs = map {

        my $value = exists $set->{ $_ } 
            ? $set->{ $_ } : Test::Smoke::Smoker->config( $_ );
        ( $_ => $value )
    } keys %$default;

    return \%mkargs;
}
