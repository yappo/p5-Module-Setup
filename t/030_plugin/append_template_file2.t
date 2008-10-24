use Module::Setup::Test::Utils;
use Test::More tests => 4;
use Fcntl qw( :mode );

use t::Plugin::AppendTemplateFile2Template;

default_dialog;
ok module_setup { target => 1 , plugins => ['+t::Plugin::AppendTemplateFile2'] }, 'AppendTemplateFile2';

ok !-f target_dir('AppendTemplateFile2')->file('append.txt');
my $append = target_dir('AppendTemplateFile2')->file('append_caller.txt');
ok -f $append;
like $append->slurp, qr/append caller/;
