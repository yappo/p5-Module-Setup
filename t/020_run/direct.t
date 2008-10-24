use Module::Setup::Test::Utils;
use Test::More tests => 3;

module_setup { flavor_class => '+t::Flavor::Direct', direct => 1, target => 1 }, 'FromDirect';

ok -d target_dir('FromDirect');
ok -f target_dir('FromDirect')->file('DirectFile.txt');

my $file = target_dir('FromDirect')->file('DirectFile.txt')->slurp;
like $file, qr/Direct Content/;
