use t::Utils;
use Test::More tests => 44;
use YAML ();

default_dialog;
module_setup { init => 1 };
module_setup { additional => 'AddTest', flavor_class => '+t::Flavor::Additional' }, 'default';

my $fh = additional_dir('default')->file('dummy')->openw;
print $fh "DUMMY";
close $fh;
like additional_dir('default')->file('dummy')->slurp, qr/DUMMY/;

do {
    ok -f additional_dir('default', 'AddTest')->file('additional.txt');
    like additional_dir('default', 'AddTest')->file('additional.txt')->slurp, qr/additional file/;
    ok -d additional_dir('default', 'AddTest', 'addir');
    is YAML::LoadFile(additional_config_file('default'))->{AddTest}->{class}, 't::Flavor::Additional';
};

dialog {
    my($self, $msg, $default) = @_;
    return 'n' if $msg =~ /Check Makefile.PL\?/i;
    return 'n' if $msg =~ /Subversion friendly\?/i;
    return 'y' if $msg =~ /Do you install additional template by .+\?/;
    return 'y' if $msg =~ /wadditional.txt exists. Override\?/;
    return $default;
};

do {
    module_setup { target => 1 }, 'NoAdd';
    ok -d target_dir 'NoAdd';

    module_setup { target => 1 }, 'Add';
    ok -d target_dir 'Add';
    ok -f target_dir('Add')->file('additional.txt');
    like target_dir('Add')->file('additional.txt')->slurp, qr/additional file/;
};

do {
    module_setup { init => 1, flavor_class => '+t::Flavor::WithAdditional' }, 'withflavor';
    ok -d additional_dir('withflavor', 'with');
    ok -f additional_dir('withflavor', 'with')->file('wadditional.txt');
    like additional_dir('withflavor', 'with')->file('wadditional.txt')->slurp, qr/additional wfile/;
    ok -d additional_dir('withflavor', 'with', 'waddir');
    is YAML::LoadFile(additional_config_file('withflavor'))->{with}->{class}, 't::Flavor::WithAdditional';
};

do {
    module_setup { additional => 'withTest', flavor_class => '+t::Flavor::Additional' }, 'withflavor';
    ok -d additional_dir('withflavor', 'withTest', 'addir');
    ok -f additional_dir('withflavor', 'withTest')->file('additional.txt');
    like additional_dir('withflavor', 'withTest')->file('additional.txt')->slurp, qr/additional file/;
    is YAML::LoadFile(additional_config_file('withflavor'))->{with}->{class}, 't::Flavor::WithAdditional';
    is YAML::LoadFile(additional_config_file('withflavor'))->{withTest}->{class}, 't::Flavor::Additional';
};

do {
    like additional_dir('withflavor', 'with')->file('wadditional.txt')->slurp, qr/additional wfile/;
    my $fh = additional_dir('withflavor', 'with')->file('wadditional.txt')->openw;
    print $fh 'rewrite';
    close $fh;
    like additional_dir('withflavor', 'with')->file('wadditional.txt')->slurp, qr/rewrite/;

    module_setup { additional => 'withAddTest', flavor_class => '+t::Flavor::WithAdditional' }, 'withflavor';
    ok -d additional_dir('withflavor', 'withAddTest', 'addir');
    ok -f additional_dir('withflavor', 'withAddTest')->file('additional.txt');
    like additional_dir('withflavor', 'withAddTest')->file('additional.txt')->slurp, qr/additional file/;
    ok !-d additional_dir('withflavor', 'withAddTest', 'waddir');
    ok !-f additional_dir('withflavor', 'withAddTest')->file('wadditional.txt');
    like additional_dir('withflavor', 'with')->file('wadditional.txt')->slurp, qr/additional wfile/;

    is YAML::LoadFile(additional_config_file('withflavor'))->{with}->{class}, 't::Flavor::WithAdditional';
    is YAML::LoadFile(additional_config_file('withflavor'))->{withTest}->{class}, 't::Flavor::Additional';
    is YAML::LoadFile(additional_config_file('withflavor'))->{withAddTest}->{class}, 't::Flavor::WithAdditional';
};

do {
    use t::Plugin::AdditionalCheck;
    no warnings 'redefine';
    local *t::Plugin::AdditionalCheck::after_create_skeleton = sub {
        my($self, $context) = @_;
        my @additionals = @{ $context->distribute->additionals };
        is grep({ $_->{class} eq 't::Flavor::Additional' } @additionals), 1;
        is grep({ $_->{class} eq 't::Flavor::WithAdditional' } @additionals), 2;
        is grep({ $_->{class} eq 't::Dummy' } @additionals), 0;
    };

    module_setup { target => 1, plugins => [qw/ Additional +t::Plugin::AdditionalCheck /] }, 'With', 'withflavor';
    ok -d target_dir('With', 'addir');
    ok -d target_dir('With', 'waddir');
    ok -f target_dir('With')->file('additional.txt');
    like target_dir('With')->file('additional.txt')->slurp, qr/additional file/;;
    ok -f target_dir('With')->file('wadditional.txt');
    like target_dir('With')->file('wadditional.txt')->slurp, qr/additional wfile/;;
};


default_dialog;
do {
    module_setup { target => 1, plugins => [qw/ Additional /] }, 'DefaultWith', 'withflavor';
    ok -d target_dir('DefaultWith', 'addir');
    ok !-d target_dir('DefaultWith', 'waddir');
    ok -f target_dir('DefaultWith')->file('additional.txt');
    like target_dir('DefaultWith')->file('additional.txt')->slurp, qr/additional file/;;
    ok !-f target_dir('DefaultWith')->file('wadditional.txt');
};
