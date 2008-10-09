use strict;
use Test::More tests => 3;
use File::Temp;
use Path::Class;

use Module::Setup;

my $module_setup_dir = File::Temp->newdir;
my $target           = File::Temp->newdir;
Module::Setup->new(
    options => {
        direct           => 1,
        flavor_class     => '+t::Flavor::Direct',
        module_setup_dir => $module_setup_dir,
        target           => $target,
    },
    argv => [ 'FromDirect' ],
)->run;

ok -d Path::Class::Dir->new( $target, 'FromDirect' );
ok -f Path::Class::File->new( $target, 'FromDirect', 'DirectFile.txt' );

my $file = Path::Class::File->new( $target, 'FromDirect', 'DirectFile.txt' )->slurp;
like $file, qr/Direct Content/;
