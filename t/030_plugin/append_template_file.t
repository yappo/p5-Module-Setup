use t::Utils;
use Test::More tests => 5;
use Fcntl qw( :mode );

default_dialog;
ok module_setup { target => 1 , plugins => ['+t::Plugin::AppendTemplateFile'] }, 'AppendTemplateFile';

my $append = target_dir('AppendTemplateFile')->file('append.txt');
ok -f $append;
like $append->slurp, qr/append/;
is sprintf('%03o', S_IMODE(( stat ($append) )[2])), '611';

ok -d target_dir 'AppendTemplateFile', 'add';
