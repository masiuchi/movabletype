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

sub save_placements {
    my $class = shift;
    my ( $entry, $item, $param ) = @_;

    my @categories;
    my $changed = 0;

    if ( $param->{page} ) {
        if ( my $folders = $param->{__permaLink_folders} ) {
            my $parent_id = 0;
            my $folder;
            require MT::Folder;
            for my $basename (@$folders) {
                $folder = MT::Folder->load(
                    {   blog_id  => $entry->blog_id,
                        parent   => $parent_id,
                        basename => $basename,
                    }
                );

                if ( !$folder ) {

                    # Autovivify the folder tree.
                    $folder = MT::Folder->new;
                    $folder->blog_id( $entry->blog_id );
                    $folder->parent($parent_id);
                    $folder->basename($basename);
                    $folder->label($basename);
                    $changed = 1;
                    $folder->save
                        or die MT::XMLRPCServer::Util::fault(
                        MT->translate(
                            "Saving folder failed: [_1]",
                            $folder->errstr
                        )
                        );
                }

                $parent_id = $folder->id;
            }
            @categories = ($folder) if $folder;
        }
    }
    elsif ( my $cats = $item->{categories} ) {
        if (@$cats) {
            my $cat_class = MT->model('category');

            # The spec says to ignore invalid category names.
            @categories
                = grep {defined}
                $cat_class->search(
                { blog_id => $entry->blog_id, label => $cats, } );
        }
    }

    require MT::Placement;
    my $is_primary_placement = 1;
CATEGORY: for my $category (@categories) {
        my $place;
        if ($is_primary_placement) {
            $place = MT::Placement->load(
                { entry_id => $entry->id, is_primary => 1, } );
        }
        if ( !$place ) {
            $place = MT::Placement->new;
            $place->blog_id( $entry->blog_id );
            $place->entry_id( $entry->id );
            $place->is_primary( $is_primary_placement ? 1 : 0 );
        }
        $place->category_id( $category->id );
        $place->save
            or die MT::XMLRPCServer::Util::fault(
            MT->translate( "Saving placement failed: [_1]", $place->errstr )
            );

        if ($is_primary_placement) {

            # Delete all the secondary placements, so each of the remaining
            # iterations of the loop make a brand new placement.
            my @old_places = MT::Placement->load(
                { entry_id => $entry->id, is_primary => 0, } );
            for my $place (@old_places) {
                $place->remove;
            }
        }

        $is_primary_placement = 0;
    }

    $changed;
}

1;

