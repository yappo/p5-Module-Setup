use t::Utils;
use Test::More tests => 1;

my $module_setup_dir = File::Temp->newdir;
my $target           = File::Temp->newdir;
eval {
    module_setup { flavor_class => '+t::Flavor::IllegalPlugin', target => 1 }, 'IllegalPlugin';
};
like $@, qr/Can't locate IllegalPlugin.pm/;
