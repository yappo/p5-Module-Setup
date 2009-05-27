use Module::Setup::Test::Utils;
use Test::More tests => 3;

use t::Helper::Basic;

my $setup = t::Helper::Basic->new(
    argv    => [qw/ Test::App /],
    options => {
        target => target_dir,
    },
);
$setup->run;

ok -d target_dir 'Test-App';
ok -f target_dir('Test-App')->file('simple.txt');
like target_dir('Test-App')->file('simple.txt')->slurp, qr{Test::App\nTest/App}ms;
