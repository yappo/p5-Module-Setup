use t::Utils;
use Test::More tests => 1;

module_setup { flavor_class => '+t::Flavor::IllegalPluginConfig', target => 1 }, 'IllegalPluginConfig';
is scalar(%{ t::Utils::context->{loaded_plugin} }), 0;
