use Module::Setup::Test::Utils;
use Test::More tests => 1;

default_dialog;
module_setup { init => 1 }, 'Dupe';
eval { module_setup { init => 1 }, 'Dupe' };
like $@, qr/create flavor: Dupe exists/;

