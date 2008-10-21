use strict;
use warnings;
use Test::More tests => 1;
use File::Temp;
use Path::Class;

use Module::Setup;

my $module_setup_dir = File::Temp->newdir;
my $target           = File::Temp->newdir;
eval {
    Module::Setup->new(
        options => {
            flavor_class     => '+t::Flavor::IllegalPlugin',
            module_setup_dir => $module_setup_dir,
            target           => $target,
        },
        argv => [ 'LocalPlugin' ],
    )->run;
};
like $@, qr/Can't locate IllegalPlugin.pm/;
