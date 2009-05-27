use Module::Setup::Test::Utils;
use Test::More tests => 2;

chdir target_dir;

use t::Helper::Basic::Foo;

my $setup = t::Helper::Basic::Foo->new(
    argv    => [qw/ Test::App /],
    helper => {
        target => 'Foo::Bar',
    },
);
$setup->run;

ok -f target_dir->file('simple.txt');
like target_dir->file('simple.txt')->slurp, qr{Test::App\nTest/App\nFoo::Bar\nFoo/Bar}ms;
