use strict;
use warnings;

use Test::More;

use lib qw( t/lib lib extlib );
use MT::Test qw( :db );
use MT;
use MT::Test::Permission;

my $author = MT::Test::Permission->make_author;
$author->can_edit_templates(1);
$author->save or die $author->errstr;

my $website = MT->model('website')->load(1) or die;
my $role_contributor = MT->model('role')->load( { name => 'Contributor' } )
    or die;

MT->model('association')->link( $author, $role_contributor, $website );

my $blog_permission = $author->permissions($website->id);
ok( $blog_permission->permissions =~ /'edit_templates'/);
$blog_permission->save or die $blog_permission->errstr;
ok( $blog_permission->permissions !~ /'edit_templates'/ );

done_testing;
