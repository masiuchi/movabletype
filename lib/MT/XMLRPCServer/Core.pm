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

sub apply_basename {
    my $class = shift;
    my ( $entry, $item, $param ) = @_;

    my $basename = $item->{mt_basename} || $item->{wp_slug};
    if ( $param->{page} && $item->{permaLink} ) {
        local $entry->{column_values}->{basename} = '##s##';
        my $real_url = $entry->archive_url();
        my ( $pre, $post ) = split /##s##/, $real_url, 2;

        my $req_url = $item->{permaLink};
        if ( $req_url =~ m{ \A \Q$pre\E (.*) \Q$post\E \z }xms ) {
            my $req_base = $1;
            my @folders = split /\//, $req_base;
            $basename = pop @folders;
            $param->{__permaLink_folders} = \@folders;
        }
        else {
            die MT::XMLRPCServer::Util::fault(
                MT->translate(
                    "Requested permalink '[_1]' is not available for this page",
                    $req_url
                )
            );
        }
    }

    if ( defined $basename ) {

        # Ensure this basename is unique.
        my $entry_class   = ref $entry;
        my $basename_uses = $entry_class->exist(
            {   blog_id  => $entry->blog_id,
                basename => $basename,
                (   $entry->id
                    ? ( id => { op => '!=', value => $entry->id } )
                    : ()
                ),
            }
        );
        if ($basename_uses) {
            require MT::Util;
            $basename = MT::Util::make_unique_basename($entry);
        }

        $entry->basename($basename);
    }

    1;
}

1;

