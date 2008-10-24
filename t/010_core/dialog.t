use Module::Setup::Test::Utils;
use Test::More tests => 5;

my @ans = qw( 1 2 3 4 );
$Module::Setup::HAS_TERM = 1;
no warnings 'redefine';
local *Module::Setup::prompt = sub ($;$) {
    my($msg, $default) = @_;
    shift @ans;
};

ok @ans;
is(Module::Setup->dialog('hoge', 1), 1);
is(Module::Setup->dialog('hoge', 1, +{}), 2);
is(Module::Setup->dialog('hoge', 1, sub { $_[1] eq '4' }), 4);
ok !@ans;
