use t::Utils;
use Test::More tests => 2;

module_setup { flavor_class => '+t::Flavor::Null', target => 1 }, 'Null';

ok target_dir('Null')->is_dir;
is target_dir('Null')->children, 0;

