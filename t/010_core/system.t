use t::Utils;
use Test::More;

system 'perl', '-e', '';
plan skip_all => "perl is not installed." if $?;
plan tests => 2;

Module::Setup->system('perl', '-e', 'exit 0');
ok !$?;

Module::Setup->system('perl', '-e', 'exit 1');
ok $?;
