package MT::XMLRPCServer::Core;
use strict;
use warnings;

use MT;
use MT::XMLRPCServer::Util;

sub login {
    my $class = shift;
    my ( $user, $pass, $blog_id ) = @_;

    my $mt  = MT::XMLRPCServer::Util::mt_new();
    my $enc = $mt->config('PublishCharset');
    require MT::Author;
    my $author = MT::Author->load( { name => $user, type => 1 } ) or return;
    die MT::XMLRPCServer::Util::fault(
        MT->translate(
            "No web services password assigned.  Please see your user profile to set it."
        )
    ) unless $author->api_password;
    die MT::XMLRPCServer::Util::fault(
        MT->translate("Failed login attempt by disabled user '[_1]'") )
        unless $author->is_active;
    my $auth = $author->api_password eq $pass;
    $auth ||= crypt( $pass, $author->api_password ) eq $author->api_password;
    return unless $auth;
    return $author unless $blog_id;
    require MT::Permission;
    my $perms = MT::Permission->load(
        {   author_id => $author->id,
            blog_id   => $blog_id
        }
    );

    ( $author, $perms );
}

sub publish {
    my $class = shift;
    my ( $mt, $entry, $no_ping, $old_categories ) = @_;
    require MT::Blog;
    my $blog = MT::Blog->load( $entry->blog_id );
    $mt->rebuild_entry(
        Entry => $entry,
        Blog  => $blog,
        (   $old_categories
            ? ( OldCategories => join(
                    ',', map { ref $_ ? $_->id : $_ } @$old_categories
                )
                )
            : ()
        ),
        BuildDependencies => 1
        )
        or die MT::XMLRPCServer::Util::fault(
        MT->translate( 'Publish error: [_1]', $mt->errstr ) );
    require MT::Entry;
    if ( $entry->status == MT::Entry::RELEASE() && !$no_ping ) {
        $mt->ping_and_save( Blog => $blog, Entry => $entry )
            or die MT::XMLRPCServer::Util::fault(
            MT->translate( 'Ping error: [_1]', $mt->errstr ) );
    }
    1;
}

1;

