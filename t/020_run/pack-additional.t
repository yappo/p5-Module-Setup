use Module::Setup::Test::Utils;
use Test::More tests => 19;


module_setup { init => 1 };
module_setup { additional => 'AddTest', flavor_class => '+t::Flavor::Additional' }, 'default';
module_setup { additional => 'AddTest2', flavor_class => '+t::Flavor::Additional' }, 'default';

my $fh = additional_dir('default')->file('dummy')->openw;
print $fh "DUMMY";
close $fh;
like additional_dir('default')->file('dummy')->slurp, qr/DUMMY/;

module_setup { pack => 1 }, 'All';
like stdout->[0], qr/file: Makefile.PL/;
like stdout->[0], qr/additional: AddTest/;
like stdout->[0], qr/additional: AddTest2/;
like stdout->[0], qr/file: additional.txt/;
like stdout->[0], qr/dir: addir/;

module_setup { pack => 1, additional => 'AddTest', }, 'Additional';
unlike stdout->[0], qr/file: Makefile.PL/;
unlike stdout->[0], qr/additional: AddTest/;
like stdout->[0], qr/file: additional.txt/;
like stdout->[0], qr/dir: addir/;

module_setup { pack => 1, additional => 'AddTest2', }, 'Additional';
unlike stdout->[0], qr/file: Makefile.PL/;
unlike stdout->[0], qr/additional: AddTest2/;
like stdout->[0], qr/file: additional.txt/;
like stdout->[0], qr/dir: addir/;

module_setup { pack => 1, without_additional => 1 }, 'Without';
like stdout->[0], qr/file: Makefile.PL/;
unlike stdout->[0], qr/additional: AddTest/;
unlike stdout->[0], qr/file: additional.txt/;
unlike stdout->[0], qr/dir: addir/;

eval { module_setup { pack => 1, additional => 'AddTest3', }, 'Additional' };
like $@, qr/additional template is no exist: AddTest3/;

