# Movable Type (r) Open Source (C) 2001-2013 Six Apart, Ltd.
# This program is distributed under the terms of the
# GNU General Public License, version 2.
#
# $Id$

package MT::XMLRPCServer::Util;
use strict;

use SOAP::Lite;
use Time::Local qw( timegm );

use MT;
use MT::Util qw( offset_time_list );

my ($HAVE_XML_PARSER);

BEGIN {
    eval { require XML::Parser };
    $HAVE_XML_PARSER = $@ ? 0 : 1;
}

sub have_xml_parser {
    $HAVE_XML_PARSER;
}

sub mt_new {
    my $cfg
        = $ENV{MOD_PERL}
        ? Apache->request->dir_config('MTConfig')
        : ( $ENV{MT_CONFIG} || $ENV{MT_HOME} . '/mt-config.cgi' );
    my $mt = MT->new( Config => $cfg )
        or die fault( MT->errstr );

    ## Initialize the MT::Request singleton for this particular request.
    $mt->request->reset();

    # we need to be UTF-8 here no matter which PublishCharset
    $mt->run_callbacks( 'init_app', $mt, { App => 'xmlrpc' } );
    $mt;
}

sub iso2ts {
    my ( $blog, $iso ) = @_;
    die fault( MT->translate("Invalid timestamp format") )
        unless $iso
        =~ /^(\d{4})(?:-?(\d{2})(?:-?(\d\d?)(?:T(\d{2}):(\d{2}):(\d{2})(?:\.\d+)?(Z|[+-]\d{2}:\d{2})?)?)?)?/;
    my ( $y, $mo, $d, $h, $m, $s, $offset )
        = ( $1, $2 || 1, $3 || 1, $4 || 0, $5 || 0, $6 || 0, $7 );
    if ( $offset && !MT->config->IgnoreISOTimezones ) {
        $mo--;
        $y -= 1900;
        my $time = timegm( $s, $m, $h, $d, $mo, $y );
        ## If it's not already in UTC, first convert to UTC.
        if ( $offset ne 'Z' ) {
            my ( $sign, $h, $m ) = $offset =~ /([+-])(\d{2}):(\d{2})/;
            $offset = $h * 3600 + $m * 60;
            $offset *= -1 if $sign eq '-';
            $time -= $offset;
        }
        ## Now apply the offset for this weblog.
        ( $s, $m, $h, $d, $mo, $y ) = offset_time_list( $time, $blog );
        $mo++;
        $y += 1900;
    }
    sprintf "%04d%02d%02d%02d%02d%02d", $y, $mo, $d, $h, $m, $s;
}

sub ts2iso {
    my ( $blog, $ts ) = @_;
    my ( $yr, $mo, $dy, $hr, $mn, $sc ) = unpack( 'A4A2A2A2A2A2A2', $ts );
    $ts = timegm( $sc, $mn, $hr, $dy, $mo, $yr );
    ( $sc, $mn, $hr, $dy, $mo, $yr ) = offset_time_list( $ts, $blog, '-' );
    $yr += 1900;
    sprintf( "%04d-%02d-%02d %02d:%02d:%02d", $yr, $mo, $dy, $hr, $mn, $sc );
}

sub fault {
    my $enc = mt_new()->config('PublishCharset');
    SOAP::Fault->faultcode(1)
        ->faultstring( SOAP::Data->type( string => $_[0] || '' ) );
}

sub validate_params {
    my ($params) = @_;

    foreach my $p (@$params) {
        die fault( MT->translate("Invalid parameter") )
            if ( 'ARRAY' eq ref $p )
            or ( 'HASH' eq ref $p );
    }

    return 1;
}

1;

