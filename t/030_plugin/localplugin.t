use strict;
use warnings;
use Test::More tests => 4;
use File::Temp;
use Path::Class;

use Module::Setup;

my $module_setup_dir = File::Temp->newdir;
my $target           = File::Temp->newdir;
Module::Setup->new(
    options => {
        flavor_class     => '+t::Flavor::LocalPlugin',
        module_setup_dir => $module_setup_dir,
        target           => $target,
    },
    argv => [ 'LocalPlugin' ],
)->run;

ok -f Path::Class::Dir->new( $module_setup_dir, 'flavors', 'default', 'plugins', 'localplugin.pm' );

ok -f Path::Class::Dir->new( $module_setup_dir, 'flavors', 'default', 'template', 'text.txt' );
ok -f Path::Class::Dir->new( $module_setup_dir, 'flavors', 'default', 'template', 'append.txt' );

ok -f Path::Class::Dir->new( $target, 'LocalPlugin', 'test.txt' );
ok -f Path::Class::Dir->new( $target, 'LocalPlugin', 'append.txt' );

no warnings 'redefine';
my $flavor;
*Module::Setup::stdout = sub { $flavor = $_[1] };
Module::Setup->new(
    options => {
        pack             => 1,
        module_setup_dir => $module_setup_dir,
    },
    argv => [ 'LocalPlugin' ],
)->run;

like $flavor, qr/package LocalPlugin;/;
like $flavor, qr!plugin: localplugin.pm!;

