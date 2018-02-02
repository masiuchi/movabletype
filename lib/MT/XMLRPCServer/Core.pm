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

sub new_entry {
    my $class = shift;
    my %param = @_;
    my ( $blog_id, $user, $pass, $item, $publish )
        = @param{qw( blog_id user pass item publish )};
    my $obj_type = $param{page} ? 'page' : 'entry';
    die MT::XMLRPCServer::Util::fault( MT->translate("No blog_id") )
        unless $blog_id;
    my $mt = MT::XMLRPCServer::Util::mt_new();   ## Will die if MT->new fails.
    for my $f (
        qw( title description mt_text_more
        mt_excerpt mt_keywords mt_tags mt_basename wp_slug )
        )
    {
        next unless defined $item->{$f};
        my $enc = $mt->{cfg}->PublishCharset;
        unless ( MT::XMLRPCServer::Util::have_xml_parser() ) {
            require MT::Util;
            $item->{$f} = MT::Util::decode_html( $item->{$f} );
            $item->{$f} =~ s!&apos;!'!g;         #'
        }
    }
    require MT::Blog;
    my $blog
        = MT::Blog->load( { id => $blog_id, class => [ 'blog', 'website' ] } )
        or die MT::XMLRPCServer::Util::fault(
        MT->translate( "Invalid blog ID '[_1]'", $blog_id ) );
    die MT::XMLRPCServer::Util::fault(
        MT->translate( "Invalid blog ID '[_1]'", $blog_id ) )
        if !$blog->is_blog && !$param{page};
    my ( $author, $perms ) = $class->login( $user, $pass, $blog_id );
    die MT::XMLRPCServer::Util::fault( MT->translate("Invalid login") )
        unless $author;
    die MT::XMLRPCServer::Util::fault( MT->translate("Permission denied.") )
        if !$author->is_superuser
        && ( !$perms
        || !$perms->can_do('create_new_entry_via_xmlrpc_server') );
    my $entry      = MT->model($obj_type)->new;
    my $orig_entry = $entry->clone;
    $entry->blog_id($blog_id);
    $entry->author_id( $author->id );

    ## In 2.1 we changed the behavior of the $publish flag. Previously,
    ## it was used to determine the post status. That was a bad idea.
    ## So now entries added through XML-RPC are always set to publish,
    ## *unless* the user has set "NoPublishMeansDraft 1" in mt.cfg, which
    ## enables the old behavior.
    require MT::Entry;
    if ( $mt->{cfg}->NoPublishMeansDraft ) {
        $entry->status(
            $publish && ( $author->is_superuser
                || $perms->can_do('publish_new_post_via_xmlrpc_server') )
            ? MT::Entry::RELEASE()
            : MT::Entry::HOLD()
        );
    }
    else {
        $entry->status(
            (          $author->is_superuser
                    || $perms->can_do('publish_new_post_via_xmlrpc_server')
            ) ? MT::Entry::RELEASE() : MT::Entry::HOLD()
        );
    }
    $entry->allow_comments( $blog->allow_comments_default );
    $entry->allow_pings( $blog->allow_pings_default );
    $entry->convert_breaks(
        defined $item->{mt_convert_breaks}
        ? $item->{mt_convert_breaks}
        : $blog->convert_paras
    );
    $entry->allow_comments( $item->{mt_allow_comments} )
        if exists $item->{mt_allow_comments};
    $entry->title( $item->{title} ) if exists $item->{title};

    $class->apply_basename( $entry, $item, \%param );

    $entry->text( $item->{description} );
    for my $field (qw( allow_pings )) {
        my $val = $item->{"mt_$field"};
        next unless defined $val;
        die MT::XMLRPCServer::Util::fault(
            MT->translate(
                "Value for 'mt_[_1]' must be either 0 or 1 (was '[_2]')",
                $field, $val
            )
        ) unless $val == 0 || $val == 1;
        $entry->$field($val);
    }
    $entry->excerpt( $item->{mt_excerpt} )     if $item->{mt_excerpt};
    $entry->text_more( $item->{mt_text_more} ) if $item->{mt_text_more};
    $entry->keywords( $item->{mt_keywords} )   if $item->{mt_keywords};
    $entry->created_by( $author->id );

    if ( my $tags = $item->{mt_tags} ) {
        require MT::Tag;
        my $tag_delim = chr( $author->entry_prefs->{tag_delim} );
        my @tags = MT::Tag->split( $tag_delim, $tags );
        $entry->set_tags(@tags);
    }
    if ( my $urls = $item->{mt_tb_ping_urls} ) {
        $entry->to_ping_urls( join "\n", @$urls );
    }
    if ( my $iso = $item->{dateCreated} ) {
        $entry->authored_on( MT::XMLRPCServer::Util::iso2ts( $blog, $iso ) )
            || die MT::XMLRPCServer::Util::fault(
            MT->translate("Invalid timestamp format") );
        require MT::DateTime;
        $entry->status( MT::Entry::FUTURE() )
            if ( $entry->status == MT::Entry::RELEASE() )
            && (
            MT::DateTime->compare(
                blog => $blog,
                a    => $entry->authored_on,
                b    => { value => time(), type => 'epoch' }
            ) > 0
            );
    }
    $entry->discover_tb_from_entry();

    MT->run_callbacks( "api_pre_save.$obj_type", $mt, $entry, $orig_entry )
        || die MT::XMLRPCServer::Util::fault(
        MT->translate( "PreSave failed [_1]", MT->errstr ) );

    $entry->save;

    my $changed = $class->save_placements( $entry, $item, \%param );

    my @types = ($obj_type);
    if ($changed) {
        push @types, 'folder';    # folders are the only type that can be
                                  # created in _save_placements
    }
    $blog->touch(@types);
    $blog->save;

    MT->run_callbacks( "api_post_save.$obj_type", $mt, $entry, $orig_entry );

    require MT::Log;
    $mt->log(
        {   message => $mt->translate(
                "User '[_1]' (user #[_2]) added [lc,_4] #[_3]",
                $author->name, $author->id,
                $entry->id,    $entry->class_label
            ),
            level    => MT::Log::INFO(),
            class    => $obj_type,
            category => 'new',
            metadata => $entry->id
        }
    );

    if ($publish) {
        $class->publish( $mt, $entry );
    }
    delete $ENV{SERVER_SOFTWARE};
    SOAP::Data->type( string => $entry->id );
}

1;

