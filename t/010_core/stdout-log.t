use t::Utils without_stdout => 1;
use Test::More tests => 2;
use IO::Scalar;

$Module::Setup::HAS_TERM = 1;

my $out;
my $err;
tie *STDOUT, 'IO::Scalar', \$out;
tie *STDERR, 'IO::Scalar', \$err;

Module::Setup->stdout('STDOUT');
Module::Setup->log('LOG');

$Module::Setup::HAS_TERM = 0;

Module::Setup->stdout('STDOUT');
Module::Setup->log('LOG');

untie *STDOUT;
untie *STDERR;

is $out, "STDOUT\n";
is $err, "LOG\n";

