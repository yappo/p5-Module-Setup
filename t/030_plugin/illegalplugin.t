use Module::Setup::Test::Utils;
use Test::More tests => 1;

eval {
    module_setup { flavor_class => '+t::Flavor::IllegalPlugin', target => 1, module_setup_dir => setup_dir }, 'IllegalPlugin';
};
like $@, qr/Can't locate IllegalPlugin.pm/;
