use Module::Setup::Test::Utils;
use Test::More tests => 3;

chdir target_dir;

use t::Helper::Basic::Callback;

my $setup = t::Helper::Basic::Callback->new(
    argv    => [qw/ Test::App /],
);
$setup->run;

ok -d target_dir('callback');
ok -f target_dir('callback')->file('path.txt');
like target_dir('callback')->file('path.txt')->slurp, qr{this is callback var};
