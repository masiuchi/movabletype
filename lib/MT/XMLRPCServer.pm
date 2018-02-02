# Movable Type (r) Open Source (C) 2001-2013 Six Apart, Ltd.
# This program is distributed under the terms of the
# GNU General Public License, version 2.
#
# $Id$

package MT::XMLRPCServer;
use strict;

use MT;
use MT::Util;
use MT::XMLRPCServer::Core;
use MT::XMLRPCServer::Util;

sub newPost {
    my $class = shift;
    my ( $appkey, $blog_id, $user, $pass, $item, $publish );
    if ( $class eq 'blogger' ) {
        ( $appkey, $blog_id, $user, $pass, my ($content), $publish ) = @_;
        $item->{description} = $content;
    }
    else {
        ( $blog_id, $user, $pass, $item, $publish ) = @_;
    }

    MT::XMLRPCServer::Util::validate_params(
        [ $blog_id, $user, $pass, $publish ] );
    my $values;
    foreach my $k ( keys %$item ) {
        if ( 'categories' eq $k || 'mt_tb_ping_urls' eq $k ) {

            # XMLRPC supports categories array and mt_tb_ping_urls array
            MT::XMLRPCServer::Util::validate_params( \@{ $item->{$k} } );
        }
        else {
            push @$values, $item->{$k};
        }
    }
    MT::XMLRPCServer::Util::validate_params( \@$values );

    MT::XMLRPCServer::Core->new_entry(
        blog_id => $blog_id,
        user    => $user,
        pass    => $pass,
        item    => $item,
        publish => $publish
    );
}

sub newPage {
    my $class = shift;
    my ( $blog_id, $user, $pass, $item, $publish ) = @_;

    MT::XMLRPCServer::Util::validate_params(
        [ $blog_id, $user, $pass, $publish ] );
    my $values;
    foreach my $k ( keys %$item ) {
        if ( 'mt_tb_ping_urls' eq $k ) {

            # XMLRPC supports mt_tb_ping_urls array
            MT::XMLRPCServer::Util::validate_params( \@{ $item->{$k} } );
        }
        else {
            push @$values, $item->{$k};
        }
    }
    MT::XMLRPCServer::Util::validate_params( \@$values );

    MT::XMLRPCServer::Core->new_entry(
        blog_id => $blog_id,
        user    => $user,
        pass    => $pass,
        item    => $item,
        publish => $publish,
        page    => 1
    );
}

sub editPost {
    my $class = shift;
    my ( $entry_id, $user, $pass, $item, $publish );
    if ( $class eq 'blogger' ) {
        ( my ($appkey), $entry_id, $user, $pass, my ($content), $publish )
            = @_;
        $item->{description} = $content;
    }
    else {
        ( $entry_id, $user, $pass, $item, $publish ) = @_;
    }

    MT::XMLRPCServer::Util::validate_params(
        [ $entry_id, $user, $pass, $publish ] );
    my $values;
    foreach my $k ( keys %$item ) {
        if ( 'categories' eq $k || 'mt_tb_ping_urls' eq $k ) {

            # XMLRPC supports categories array and mt_tb_ping_urls array
            MT::XMLRPCServer::Util::validate_params( \@{ $item->{$k} } );
        }
        else {
            push @$values, $item->{$k};
        }
    }
    MT::XMLRPCServer::Util::validate_params( \@$values );

    MT::XMLRPCServer::Core->edit_entry(
        entry_id => $entry_id,
        user     => $user,
        pass     => $pass,
        item     => $item,
        publish  => $publish
    );
}

sub editPage {
    my $class = shift;
    my ( $blog_id, $entry_id, $user, $pass, $item, $publish ) = @_;

    MT::XMLRPCServer::Util::validate_params(
        [ $blog_id, $entry_id, $user, $pass, $publish ] );
    my $values;
    foreach my $k ( keys %$item ) {
        if ( 'mt_tb_ping_urls' eq $k ) {

            # XMLRPC supports mt_tb_ping_urls array
            MT::XMLRPCServer::Util::validate_params( \@{ $item->{$k} } );
        }
        else {
            push @$values, $item->{$k};
        }
    }
    MT::XMLRPCServer::Util::validate_params( \@$values );

    MT::XMLRPCServer::Core->edit_entry(
        blog_id  => $blog_id,
        entry_id => $entry_id,
        user     => $user,
        pass     => $pass,
        item     => $item,
        publish  => $publish,
        page     => 1
    );
}

sub getUsersBlogs {
    my $class;
    if ( UNIVERSAL::isa( $_[0] => __PACKAGE__ ) ) {
        $class = shift;
    }
    else {
        $class = __PACKAGE__;
    }
    my ( $appkey, $user, $pass ) = @_;

    MT::XMLRPCServer::Util::validate_params( [ $user, $pass ] );

    my $mt = MT::XMLRPCServer::Util::mt_new();   ## Will die if MT->new fails.
    my ($author) = MT::XMLRPCServer::Core->login( $user, $pass );
    die MT::XMLRPCServer::Util::fault( MT->translate("Invalid login") )
        unless $author;

    require MT::Permission;
    require MT::Blog;

    my $iter;
    if ( $author->is_superuser ) {
        $iter = MT::Blog->load_iter();
    }
    else {
        $iter = MT::Blog->load_iter(
            {},
            {   join => MT::Permission->join_on(
                    'blog_id', { author_id => $author->id, }, {}
                )
            }
        );
    }

    my @res;
    while ( my $blog = $iter->() ) {
        if ( !$author->is_superuser ) {
            my $perm = $author->permissions( $blog->id );
            next
                unless $perm
                && $perm->can_do('get_blog_info_via_xmlrpc_server');
        }
        push @res,
            {
            url => SOAP::Data->type( string => $blog->site_url || '' ),
            blogid   => SOAP::Data->type( string => $blog->id ),
            blogName => SOAP::Data->type( string => $blog->name || '' )
            };
    }
    \@res;
}

sub getUserInfo {
    my $class;
    if ( UNIVERSAL::isa( $_[0] => __PACKAGE__ ) ) {
        $class = shift;
    }
    else {
        $class = __PACKAGE__;
    }
    my ( $appkey, $user, $pass ) = @_;

    MT::XMLRPCServer::Util::validate_params( [ $user, $pass ] );

    my $mt = MT::XMLRPCServer::Util::mt_new();   ## Will die if MT->new fails.
    my ($author) = MT::XMLRPCServer::Core->login( $user, $pass );
    die MT::XMLRPCServer::Util::fault( MT->translate("Invalid login") )
        unless $author;
    my ( $fname, $lname ) = split /\s+/, $author->name;
    $lname ||= '';
    {   userid    => SOAP::Data->type( string => $author->id ),
        firstname => SOAP::Data->type( string => $fname || '' ),
        lastname  => SOAP::Data->type( string => $lname || '' ),
        nickname  => SOAP::Data->type( string => $author->nickname || '' ),
        email     => SOAP::Data->type( string => $author->email || '' ),
        url       => SOAP::Data->type( string => $author->url || '' )
    };
}

sub getRecentPosts {
    my $class = shift;
    my ( $blog_id, $user, $pass, $num );
    if ( $class eq 'blogger' ) {
        ( my ($appkey), $blog_id, $user, $pass, $num ) = @_;
    }
    else {
        ( $blog_id, $user, $pass, $num ) = @_;
    }

    MT::XMLRPCServer::Util::validate_params(
        [ $blog_id, $user, $pass, $num ] );

    MT::XMLRPCServer::Core->get_entries(
        api_class => $class,
        blog_id   => $blog_id,
        user      => $user,
        pass      => $pass,
        num       => $num
    );
}

sub getRecentPostTitles {
    my $class = shift;
    my ( $blog_id, $user, $pass, $num ) = @_;

    MT::XMLRPCServer::Util::validate_params(
        [ $blog_id, $user, $pass, $num ] );

    MT::XMLRPCServer::Core->get_entries(
        api_class   => $class,
        blog_id     => $blog_id,
        user        => $user,
        pass        => $pass,
        num         => $num,
        titles_only => 1
    );
}

sub getPages {
    my $class = shift;
    my ( $blog_id, $user, $pass ) = @_;

    MT::XMLRPCServer::Util::validate_params( [ $blog_id, $user, $pass ] );

    MT::XMLRPCServer::Core->get_entries(
        api_class => $class,
        blog_id   => $blog_id,
        user      => $user,
        pass      => $pass,
        page      => 1
    );
}

sub deletePost {
    my $class;
    if ( UNIVERSAL::isa( $_[0] => __PACKAGE__ ) ) {
        $class = shift;
    }
    else {
        $class = __PACKAGE__;
    }
    my ( $appkey, $entry_id, $user, $pass, $publish ) = @_;

    MT::XMLRPCServer::Util::validate_params(
        [ $entry_id, $user, $pass, $publish ] );

    MT::XMLRPCServer::Core->delete_entry(
        entry_id => $entry_id,
        user     => $user,
        pass     => $pass,
        publish  => $publish
    );
}

sub deletePage {
    my $class = shift;
    my ( $blog_id, $user, $pass, $entry_id ) = @_;

    MT::XMLRPCServer::Util::validate_params(
        [ $blog_id, $user, $pass, $entry_id ] );

    MT::XMLRPCServer::Core->delete_entry(
        blog_id  => $blog_id,
        entry_id => $entry_id,
        user     => $user,
        pass     => $pass,
        publish  => 1,
        page     => 1
    );
}

sub getPost {
    my $class = shift;
    my ( $entry_id, $user, $pass ) = @_;

    MT::XMLRPCServer::Util::validate_params( [ $entry_id, $user, $pass ] );

    MT::XMLRPCServer::Core->get_entry(
        entry_id => $entry_id,
        user     => $user,
        pass     => $pass
    );
}

sub getPage {
    my $class = shift;
    my ( $blog_id, $entry_id, $user, $pass ) = @_;

    MT::XMLRPCServer::Util::validate_params(
        [ $blog_id, $entry_id, $user, $pass ] );

    MT::XMLRPCServer::Core->get_entry(
        blog_id  => $blog_id,
        entry_id => $entry_id,
        user     => $user,
        pass     => $pass,
        page     => 1
    );
}

sub supportedMethods {
    [   'blogger.newPost', 'blogger.editPost', 'blogger.getRecentPosts',
        'blogger.getUsersBlogs', 'blogger.getUserInfo', 'blogger.deletePost',
        'metaWeblog.getPost',    'metaWeblog.newPost',  'metaWeblog.editPost',
        'metaWeblog.getRecentPosts', 'metaWeblog.newMediaObject',
        'metaWeblog.getCategories',  'metaWeblog.deletePost',
        'metaWeblog.getUsersBlogs', 'wp.newPage', 'wp.getPages', 'wp.getPage',
        'wp.editPage', 'wp.deletePage',

        # not yet supported: metaWeblog.getTemplate, metaWeblog.setTemplate
        'mt.getCategoryList', 'mt.setPostCategories', 'mt.getPostCategories',
        'mt.getTrackbackPings', 'mt.supportedTextFilters',
        'mt.getRecentPostTitles', 'mt.publishPost', 'mt.getTagList'
    ];
}

sub supportedTextFilters {
    my $mt = MT::XMLRPCServer::Util::mt_new();   ## Will die if MT->new fails.
    my $filters = $mt->all_text_filters;
    my @res;
    for my $filter ( keys %$filters ) {
        my $label = $filters->{$filter}{label};
        if ( 'CODE' eq ref($label) ) {
            $label = $label->();
        }
        push @res,
            {
            key   => SOAP::Data->type( string => $filter || '' ),
            label => SOAP::Data->type( string => $label  || '' )
            };
    }
    \@res;
}

## getCategoryList, getPostCategories, and setPostCategories were
## originally written by Daniel Drucker with the assistance of
## Six Apart, then later modified by Six Apart.

sub getCategoryList {
    my $class = shift;
    my ( $blog_id, $user, $pass ) = @_;

    MT::XMLRPCServer::Util::validate_params( [ $blog_id, $user, $pass ] );

    my $mt = MT::XMLRPCServer::Util::mt_new();   ## Will die if MT->new fails.
    my ( $author, $perms )
        = MT::XMLRPCServer::Core->login( $user, $pass, $blog_id );
    die MT::XMLRPCServer::Util::fault( MT->translate("Invalid login") )
        unless $author;
    die MT::XMLRPCServer::Util::fault( MT->translate("Permission denied.") )
        if !$author->is_superuser
        && ( !$perms
        || !$perms->can_do('get_category_list_via_xmlrpc_server') );
    require MT::Category;
    my $iter = MT::Category->load_iter( { blog_id => $blog_id } );
    my @data;

    while ( my $cat = $iter->() ) {
        push @data,
            {
            categoryName => SOAP::Data->type( string => $cat->label || '' ),
            categoryId => SOAP::Data->type( string => $cat->id )
            };
    }
    \@data;
}

sub getCategories {
    my $class = shift;
    my ( $blog_id, $user, $pass ) = @_;

    MT::XMLRPCServer::Util::validate_params( [ $blog_id, $user, $pass ] );

    my $mt = MT::XMLRPCServer::Util::mt_new();   ## Will die if MT->new fails.
    my ( $author, $perms )
        = MT::XMLRPCServer::Core->login( $user, $pass, $blog_id );
    die MT::XMLRPCServer::Util::fault( MT->translate("Invalid login") )
        unless $author;
    die MT::XMLRPCServer::Util::fault( MT->translate("Permission denied.") )
        if !$author->is_superuser
        && ( !$perms || !$perms->can_do('get_categories_via_xmlrpc_server') );
    require MT::Category;
    my $iter = MT::Category->load_iter( { blog_id => $blog_id } );
    my @data;
    my $blog = MT::Blog->load($blog_id);
    require File::Spec;

    while ( my $cat = $iter->() ) {
        my $url = File::Spec->catfile( $blog->site_url,
            MT::Util::archive_file_for( undef, $blog, 'Category', $cat ) );
        push @data,
            {
            categoryId => SOAP::Data->type( string => $cat->id ),
            parentId   => (
                $cat->parent_category
                ? SOAP::Data->type( string => $cat->parent_category->id )
                : undef
            ),
            categoryName => SOAP::Data->type( string => $cat->label || '' ),
            title        => SOAP::Data->type( string => $cat->label || '' ),
            description =>
                SOAP::Data->type( string => $cat->description || '' ),
            htmlUrl => SOAP::Data->type( string => $url || '' ),
            };
    }
    \@data;
}

sub getTagList {
    my $class = shift;
    my ( $blog_id, $user, $pass ) = @_;

    MT::XMLRPCServer::Util::validate_params( [ $blog_id, $user, $pass ] );

    my $mt = MT::XMLRPCServer::Util::mt_new();   ## Will die if MT->new fails.
    my ( $author, $perms )
        = MT::XMLRPCServer::Core->login( $user, $pass, $blog_id );
    die MT::XMLRPCServer::Util::fault( MT->translate("Invalid login") )
        unless $author;
    die MT::XMLRPCServer::Util::fault( MT->translate("Permission denied.") )
        if !$author->is_superuser
        && ( !$perms || !$perms->can_do('get_tag_list_via_xmlrpc_server') );
    require MT::Tag;
    require MT::ObjectTag;
    my $iter = MT::Tag->load_iter(
        undef,
        {   join => [
                'MT::ObjectTag', 'tag_id',
                { blog_id => $blog_id }, { unique => 1 }
            ]
        }
    );
    my @data;

    while ( my $tag = $iter->() ) {
        push @data,
            {
            tagName => SOAP::Data->type( string => $tag->name || '' ),
            tagId => SOAP::Data->type( string => $tag->id )
            };
    }
    \@data;
}

sub getPostCategories {
    my $class = shift;
    my ( $entry_id, $user, $pass ) = @_;

    MT::XMLRPCServer::Util::validate_params( [ $entry_id, $user, $pass ] );

    my $mt = MT::XMLRPCServer::Util::mt_new();   ## Will die if MT->new fails.
    require MT::Entry;
    my $entry = MT::Entry->load($entry_id)
        or die MT::XMLRPCServer::Util::fault(
        MT->translate( "Invalid entry ID '[_1]'", $entry_id ) );
    my ( $author, $perms )
        = MT::XMLRPCServer::Core->login( $user, $pass, $entry->blog_id );
    die MT::XMLRPCServer::Util::fault( MT->translate("Invalid login") )
        unless $author;
    die MT::XMLRPCServer::Util::fault( MT->translate("Permission denied.") )
        if !$author->is_superuser
        && ( !$perms
        || !$perms->can_do('get_post_categories_via_xmlrpc_server') );
    my @data;
    my $prim = $entry->category;
    my $cats = $entry->categories;

    for my $cat (@$cats) {
        my $is_primary = $prim && $cat->id == $prim->id ? 1 : 0;
        push @data,
            {
            categoryName => SOAP::Data->type( string => $cat->label || '' ),
            categoryId => SOAP::Data->type( string => $cat->id ),
            isPrimary => SOAP::Data->type( boolean => $is_primary ),
            };
    }
    \@data;
}

sub setPostCategories {
    my $class = shift;
    my ( $entry_id, $user, $pass, $cats ) = @_;

    MT::XMLRPCServer::Util::validate_params( [ $entry_id, $user, $pass ] );
    foreach my $c (@$cats) {
        MT::XMLRPCServer::Util::validate_params( [ values %$c ] );
    }

    my $mt = MT::XMLRPCServer::Util::mt_new();   ## Will die if MT->new fails.
    require MT::Entry;
    require MT::Placement;
    my $entry = MT::Entry->load($entry_id)
        or die MT::XMLRPCServer::Util::fault(
        MT->translate( "Invalid entry ID '[_1]'", $entry_id ) );
    my ( $author, $perms )
        = MT::XMLRPCServer::Core->login( $user, $pass, $entry->blog_id );
    die MT::XMLRPCServer::Util::fault( MT->translate("Invalid login") )
        unless $author;
    die MT::XMLRPCServer::Util::fault(
        MT->translate("Not allowed to set entry categories") )
        if !$author->is_superuser
        && ( !$perms || !$perms->can_edit_entry( $entry, $author ) );
    my @place = MT::Placement->load( { entry_id => $entry_id } );

    for my $place (@place) {
        $place->remove;
    }
    ## Keep track of which category is named the primary category.
    ## If the first structure in the array does not have an isPrimary
    ## key, we just make it the primary category; if it does, we use
    ## that flag to determine the primary category.
    my $is_primary = 1;
    for my $cat (@$cats) {
        my $place = MT::Placement->new;
        $place->entry_id($entry_id);
        $place->blog_id( $entry->blog_id );
        if ( defined $cat->{isPrimary} && $is_primary ) {
            $place->is_primary( $cat->{isPrimary} );
        }
        else {
            $place->is_primary($is_primary);
        }
        ## If we just set the is_primary flag to 1, we don't want to
        ## make any other categories primary.
        $is_primary = 0 if $place->is_primary;
        $place->category_id( $cat->{categoryId} );
        $place->save
            or die MT::XMLRPCServer::Util::fault(
            MT->translate( "Saving placement failed: [_1]", $place->errstr )
            );
    }
    MT::XMLRPCServer::Core->publish( $mt, $entry, undef,
        [ map { $_->category_id } @place ] );
    SOAP::Data->type( boolean => 1 );
}

sub getTrackbackPings {
    my $class = shift;
    my ($entry_id) = @_;

    MT::XMLRPCServer::Util::validate_params( [$entry_id] );

    require MT::Trackback;
    require MT::TBPing;
    my $mt = MT::XMLRPCServer::Util::mt_new();   ## Will die if MT->new fails.
    my $tb = MT::Trackback->load( { entry_id => $entry_id } ) or return [];
    my $iter = MT::TBPing->load_iter( { tb_id => $tb->id } );
    my @data;

    while ( my $ping = $iter->() ) {
        push @data,
            {
            pingTitle => SOAP::Data->type( string => $ping->title || '' ),
            pingURL => SOAP::Data->type( string => $ping->source_url || '' ),
            pingIP  => SOAP::Data->type( string => $ping->ip         || '' ),
            };
    }
    \@data;
}

sub publishPost {
    my $class = shift;
    my ( $entry_id, $user, $pass ) = @_;

    MT::XMLRPCServer::Util::validate_params( [ $entry_id, $user, $pass ] );

    my $mt = MT::XMLRPCServer::Util::mt_new();   ## Will die if MT->new fails.
    require MT::Entry;
    my $entry = MT::Entry->load($entry_id)
        or die MT::XMLRPCServer::Util::fault(
        MT->translate( "Invalid entry ID '[_1]'", $entry_id ) );
    my ( $author, $perms )
        = MT::XMLRPCServer::Core->login( $user, $pass, $entry->blog_id );
    die MT::XMLRPCServer::Util::fault( MT->translate("Invalid login") )
        unless $author;
    die MT::XMLRPCServer::Util::fault(
        MT->translate("Not allowed to edit entry") )
        if !$author->is_superuser
        && ( !$perms || !$perms->can_edit_entry( $entry, $author ) );
    $mt->rebuild_entry( Entry => $entry, BuildDependencies => 1 )
        or die MT::XMLRPCServer::Util::fault(
        MT->translate( "Publishing failed: [_1]", $mt->errstr ) );
    SOAP::Data->type( boolean => 1 );
}

sub runPeriodicTasks {
    my $class = shift;
    my ( $user, $pass ) = @_;

    MT::XMLRPCServer::Util::validate_params( [ $user, $pass ] );

    my $mt = MT::XMLRPCServer::Util::mt_new();
    my $author = MT::XMLRPCServer::Core->login( $user, $pass );
    die MT::XMLRPCServer::Util::fault( MT->translate("Invalid login") )
        unless $author;

    $mt->run_tasks;

    { responseCode => 'success' };
}

sub publishScheduledFuturePosts {
    my $class = shift;
    my ( $blog_id, $user, $pass ) = @_;

    MT::XMLRPCServer::Util::validate_params( [ $blog_id, $user, $pass ] );

    my $mt = MT::XMLRPCServer::Util::mt_new();
    my $author = MT::XMLRPCServer::Core->login( $user, $pass );
    die MT::XMLRPCServer::Util::fault( MT->translate("Invalid login") )
        unless $author;
    my $blog = MT::Blog->load($blog_id)
        or die MT::XMLRPCServer::Util::fault(
        MT->translate( 'Cannot load blog #[_1].', $blog_id ) );

    my $now = time;

    # Convert $now to user's timezone, which is how future post dates
    # are stored.
    $now = MT::Util::offset_time($now);
    $now = strftime( "%Y%m%d%H%M%S", gmtime($now) );

    my $iter = MT::Entry->load_iter(
        {   blog_id => $blog->id,
            class   => '*',
            status  => MT::Entry::FUTURE()
        },
        {   'sort'    => 'authored_on',
            direction => 'descend'
        }
    );
    my @queue;
    while ( my $i = $iter->() ) {
        push @queue, $i->id();
    }

    my $changed       = 0;
    my $total_changed = 0;
    my @results;
    my %types;
    foreach my $entry_id (@queue) {
        my $entry = MT::Entry->load($entry_id);
        if ( $entry && $entry->authored_on <= $now ) {
            $entry->status( MT::Entry::RELEASE() );
            $entry->discover_tb_from_entry();
            $entry->save or die $entry->errstr;

            $types{ $entry->class } = 1;
            MT::Util::start_background_task(
                sub {
                    $mt->rebuild_entry( Entry => $entry, Blog => $blog )
                        or die $mt->errstr;
                }
            );
            $changed++;
            $total_changed++;
        }
    }
    $blog->touch( keys %types ) if $changed;
    $blog->save if $changed && ( keys %types );

    if ($changed) {
        $mt->rebuild_indexes( Blog => $blog ) or die $mt->errstr;
    }
    { responseCode => 'success', publishedCount => $total_changed, };
}

sub getNextScheduled {
    my $class = shift;
    my ( $user, $pass ) = @_;

    MT::XMLRPCServer::Util::validate_params( [ $user, $pass ] );

    my $mt = MT::XMLRPCServer::Util::mt_new();
    my $author = MT::XMLRPCServer::Core->login( $user, $pass );
    die MT::XMLRPCServer::Util::fault( MT->translate("Invalid login") )
        unless $author;

    my $next_scheduled = MT::get_next_sched_post_for_user( $author->id() );

    { nextScheduledTime => $next_scheduled };
}

sub setRemoteAuthToken {
    my $class = shift;
    my ( $user, $pass, $remote_auth_username, $remote_auth_token ) = @_;

    MT::XMLRPCServer::Util::validate_params(
        [ $user, $pass, $remote_auth_username, $remote_auth_token ] );

    my $mt = MT::XMLRPCServer::Util::mt_new();   ## Will die if MT->new fails.
    my ($author) = MT::XMLRPCServer::Core->login( $user, $pass );
    die MT::XMLRPCServer::Util::fault( MT->translate("Invalid login") )
        unless $author;
    $author->remote_auth_username($remote_auth_username);
    $author->remote_auth_token($remote_auth_token);
    $author->save();
    1;
}

sub newMediaObject {
    my $class = shift;
    my ( $blog_id, $user, $pass, $file ) = @_;

    MT::XMLRPCServer::Util::validate_params( [ $blog_id, $user, $pass ] );
    MT::XMLRPCServer::Util::validate_params( [ values %$file ] );

    my $mt = MT::XMLRPCServer::Util::mt_new();   ## Will die if MT->new fails.
    my ( $author, $perms )
        = MT::XMLRPCServer::Core->login( $user, $pass, $blog_id );
    die MT::XMLRPCServer::Util::fault( MT->translate("Invalid login") )
        unless $author;
    die MT::XMLRPCServer::Util::fault(
        MT->translate("Not allowed to upload files") )
        if !$author->is_superuser
        && ( !$perms || !$perms->can_do('upload_asset_via_xmlrpc_server') );

    require MT::Blog;
    require File::Spec;
    my $blog = MT::Blog->load($blog_id)
        or die MT::XMLRPCServer::Util::fault(
        MT->translate( 'Cannot load blog #[_1].', $blog_id ) );

    my $fname = $file->{name}
        or die MT::XMLRPCServer::Util::fault(
        MT->translate("No filename provided") );
    if ( $fname =~ m!\.\.|\0|\|! ) {
        die MT::XMLRPCServer::Util::fault(
            MT->translate( "Invalid filename '[_1]'", $fname ) );
    }

    if ( my $deny_exts = MT->config->DeniedAssetFileExtensions ) {
        my @deny_exts = map {
            if   ( $_ =~ m/^\./ ) {qr/$_/i}
            else                  {qr/\.$_/i}
        } split '\s?,\s?', $deny_exts;
        my @ret = File::Basename::fileparse( $fname, @deny_exts );
        die MT::XMLRPCServer::Util::fault(
            MT->translate(
                'The file ([_1]) that you uploaded is not allowed.', $fname
            )
        ) if $ret[2];
    }

    if ( my $allow_exts = MT->config('AssetFileExtensions') ) {
        my @allowed = map {
            if   ( $_ =~ m/^\./ ) {qr/$_/i}
            else                  {qr/\.$_/i}
        } split '\s?,\s?', $allow_exts;
        my @ret = File::Basename::fileparse( $fname, @allowed );
        die MT::XMLRPCServer::Util::fault(
            MT->translate(
                'The file ([_1]) that you uploaded is not allowed.', $fname
            )
        ) unless $ret[2];
    }

    my $local_file = File::Spec->catfile( $blog->site_path, $file->{name} );
    my $ext
        = ( File::Basename::fileparse( $local_file, qr/[A-Za-z0-9]+$/ ) )[2];
    require MT::Asset::Image;
    if ( MT::Asset::Image->can_handle($ext) ) {
        require MT::Image;
        my $fh;
        my $data = $file->{bits};
        open( $fh, "+<", \$data );
        close($fh),
            die MT::XMLRPCServer::Util::fault(
            MT->translate(
                "Saving [_1] failed: [_2]",
                $file->{name},
                "Invalid image file format."
            )
            ) unless MT::Image::is_valid_image($fh);
        close($fh);
    }

    my $fmgr = $blog->file_mgr;
    my ( $vol, $path, $name ) = File::Spec->splitpath($local_file);
    $path =~ s!/$!!
        unless $path eq '/';    ## OS X doesn't like / at the end in mkdir().
    $path = File::Spec->catpath( $vol, $path )
        if $vol;
    unless ( $fmgr->exists($path) ) {
        $fmgr->mkpath($path)
            or die MT::XMLRPCServer::Util::fault(
            MT->translate(
                "Error making path '[_1]': [_2]",
                $path, $fmgr->errstr
            )
            );
    }
    defined( my $bytes
            = $fmgr->put_data( $file->{bits}, $local_file, 'upload' ) )
        or die MT::XMLRPCServer::Util::fault(
        MT->translate( "Error writing uploaded file: [_1]", $fmgr->errstr ) );
    my $url = $blog->site_url . $fname;

    require File::Basename;
    my $local_basename = File::Basename::basename($local_file);
    eval { require Image::Size; };
    die MT::XMLRPCServer::Util::fault(
        MT->translate(
            "Perl module Image::Size is required to determine width and height of uploaded images."
        )
    ) if $@;
    my ( $w, $h, $id ) = Image::Size::imgsize($local_file);

    require MT::Asset;
    my $asset_pkg = MT::Asset->handler_for_file($local_basename);
    my $is_image  = 0;
    if ( defined($w) && defined($h) ) {
        $is_image = 1 if $asset_pkg->isa('MT::Asset::Image');
    }
    else {

        # rebless to file type
        $asset_pkg = 'MT::Asset';
    }

    my $asset;
    if (!(  $asset = $asset_pkg->load(
                { file_path => $local_file, blog_id => $blog_id }
            )
        )
        )
    {
        $asset = $asset_pkg->new();
        $asset->file_path($local_file);
        $asset->file_name($local_basename);
        $asset->file_ext($ext);
        $asset->blog_id($blog_id);
        $asset->created_by( $author->id );
    }
    else {
        $asset->modified_by( $author->id );
    }
    my $original = $asset->clone;
    $asset->url($url);
    if ($is_image) {
        $asset->image_width($w);
        $asset->image_height($h);
    }
    $asset->mime_type( $file->{type} );
    $asset->save;

    $blog->touch('asset');
    $blog->save;

    MT->run_callbacks(
        'api_upload_file.' . $asset->class,
        File  => $local_file,
        file  => $local_file,
        Url   => $url,
        url   => $url,
        Size  => $bytes,
        size  => $bytes,
        Asset => $asset,
        asset => $asset,
        Type  => $asset->class,
        type  => $asset->class,
        Blog  => $blog,
        blog  => $blog
    );
    if ($is_image) {
        MT->run_callbacks(
            'api_upload_image',
            File       => $local_file,
            file       => $local_file,
            Url        => $url,
            url        => $url,
            Size       => $bytes,
            size       => $bytes,
            Asset      => $asset,
            asset      => $asset,
            Height     => $h,
            height     => $h,
            Width      => $w,
            width      => $w,
            Type       => 'image',
            type       => 'image',
            ImageType  => $id,
            image_type => $id,
            Blog       => $blog,
            blog       => $blog
        );
    }

    { url => SOAP::Data->type( string => $url || '' ) };
}

## getTemplate and setTemplate are not applicable in MT's template
## structure, so they are unimplemented (they return a fault).
## We assign it twice to get rid of "setTemplate used only once" warnings.

sub getTemplate {
    die MT::XMLRPCServer::Util::fault(
        MT->translate(
            "Template methods are not implemented, due to differences between the Blogger API and the Movable Type API."
        )
    );
}
*setTemplate = *setTemplate = \&getTemplate;

## The above methods will be called as blogger.newPost, blogger.editPost,
## etc., because we are implementing Blogger's API. Thus, the empty
## subclass.
package blogger;
use base 'MT::XMLRPCServer';

package metaWeblog;
use base 'MT::XMLRPCServer';

package mt;
use base 'MT::XMLRPCServer';

package wp;
use base 'MT::XMLRPCServer';

1;
__END__

=head1 NAME

MT::XMLRPCServer

=head1 SYNOPSIS

An XMLRPC API interface for communicating with Movable Type.

=head1 CALLBACKS

=over 4

=item api_pre_save.entry
=item api_pre_save.page

    callback($eh, $mt, $entry, $original_entry)

Called before saving a new or existing entry. If saving a new entry, the
$original_entry will have an unassigned 'id'. This callback is executed
as a filter, so your handler must return 1 to allow the entry to be saved.

=item api_post_save.entry
=item api_post_save.page

    callback($eh, $mt, $entry, $original_entry)

Called after saving a new or existing entry. If saving a new entry, the
$original_entry will have an unassigned 'id'.

=item api_upload_file

    callback($eh, %params)

This callback is invoked for each file the user uploads to the weblog.
This callback is similar to the CMSUploadFile callback found in
C<MT::App::CMS>.

=back

=head2 Parameters

=over 4

=item File

The full physical file path of the uploaded file.

=item Url

The full URL to the file that has been uploaded.

=item Type

For this callback, this value is currently always 'file'.

=item Blog

The C<MT::Blog> object associated with the newly uploaded file.

=back

=cut
