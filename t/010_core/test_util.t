use t::Utils;
use Test::More tests => 10;

ok !-d setup_dir('foo');
ok !-d target_dir('foo');

setup_dir->subdir('foo')->mkpath;
target_dir->subdir('foo')->mkpath;

ok -d setup_dir('foo');
ok -d target_dir('foo');

ok !-f setup_dir('foo')->file('setup');
ok !-f target_dir('foo')->file('target');

setup_dir->subdir('foo')->file('setup')->openw->close;
target_dir->subdir('foo')->file('target')->openw->close;

ok -f setup_dir('foo')->file('setup');
ok -f target_dir('foo')->file('target');

clear_tempdir;

ok !-d setup_dir('foo');
ok !-d target_dir('foo');
