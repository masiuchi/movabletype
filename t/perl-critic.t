use strict;
use warnings;

use Test::Perl::Critic;

my @dirs = qw( lib plugins tools t build );
my @files = grep { $_ !~ /mt-config\.cgi$/ } grep {/\.(cgi|psgi)$/} glob '*';
all_critic_ok( @dirs, @files );

