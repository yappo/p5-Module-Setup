use Module::Setup::Test::Utils;
use Test::More tests => 1;

module_setup { flavor_class => '+t::Flavor::IllegalPluginConfig', target => 1 }, 'IllegalPluginConfig';
is scalar(%{ Module::Setup::Test::Utils::context->{loaded_plugin} }), 0;
