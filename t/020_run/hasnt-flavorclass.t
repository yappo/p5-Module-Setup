use t::Utils;
use Test::More tests => 1;

eval { module_setup { flavor_class => '+DUMMY', target => 1 }, 'DUMMY' };
like $@, qr/Can't locate DUMMY.pm/;
