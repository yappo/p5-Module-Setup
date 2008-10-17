use t::Utils;
use Test::More tests => 6;

module_setup { init => 1 };

dialog {
    my($self, $msg, $default) = @_;
    return 'n' unless $msg =~ /Subversion/;
    like $msg, qr/Subversion friendly\?/;
    is $default, 'y';
    'y';
};
module_setup { target => 1 }, 'VC::SVN';
ok -d target_dir('VC-SVN', 'trunk');
ok -d target_dir('VC-SVN', 'branches');
ok -d target_dir('VC-SVN', 'tags');
ok -f target_dir('VC-SVN', 'trunk')->file('Makefile.PL');
