use t::Utils;
use Test::More tests => 4;
use YAML ();

default_dialog;
ok !module_setup { init => 1, flavor_class => '+t::Flavor::Fail' };
ok !-d setup_dir 'default';

ok !module_setup { target => 1, flavor_class => '+t::Flavor::Fail' }, 'Fail';
ok !-d setup_dir 'default';
