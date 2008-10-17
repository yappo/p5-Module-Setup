use t::Utils;
use Test::More tests => 1;

default_dialog;
ok module_setup { target => 1 , plugins => ['+t::Plugin::Plain'] }, 'Plain';
