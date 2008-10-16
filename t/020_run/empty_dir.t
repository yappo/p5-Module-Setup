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
        flavor_class     => '+t::Flavor::EmptyDir',
        module_setup_dir => $module_setup_dir,
        target           => $target,
    },
    argv => [ 'EmptyDir' ],
)->run;

ok -d Path::Class::Dir->new( $module_setup_dir, 'flavors', 'default', 'template', 'foo', 'bar', 'baz' );
ok -d Path::Class::Dir->new( $target, 'EmptyDir', 'foo', 'bar', 'baz' );

no warnings 'redefine';
my $flavor;
*Module::Setup::stdout = sub { $flavor = $_[1] };
Module::Setup->new(
    options => {
        pack             => 1,
        module_setup_dir => $module_setup_dir,
    },
    argv => [ 'FlavorEmptyDir' ],
)->run;

like $flavor, qr/package FlavorEmptyDir;/;
like $flavor, qr!dir: foo/bar/baz!;

