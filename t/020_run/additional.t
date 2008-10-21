use t::Utils;
use Test::More tests => 8;

default_dialog;
module_setup { init => 1 };
module_setup { additional => 'AddTest', flavor_class => '+t::Flavor::Additional' }, 'default';

my $fh = additional_dir('default')->file('dummy')->openw;
print $fh "DUMMY";
close $fh;
like additional_dir('default')->file('dummy')->slurp, qr/DUMMY/;


ok -f additional_dir('default', 'AddTest')->file('additional.txt');
like additional_dir('default', 'AddTest')->file('additional.txt')->slurp, qr/additional file/;
ok -d additional_dir('default', 'AddTest', 'addir');


do {
    module_setup { target => 1 }, 'NoAdd';
    ok -d target_dir 'NoAdd';

    dialog {
        my($self, $msg, $default) = @_;
        return 'n' if $msg =~ /Check Makefile.PL\?/i;
        return 'n' if $msg =~ /Subversion friendly\?/i;
        return 'y' if $msg =~ /Do you install additional template by .+\?/;
        return $default;
    };

    module_setup { target => 1 }, 'Add';
    ok -d target_dir 'Add';
    ok -f target_dir('Add')->file('additional.txt');
    like target_dir('Add')->file('additional.txt')->slurp, qr/additional file/;
};
