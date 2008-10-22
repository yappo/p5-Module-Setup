use t::Utils;
use Test::More tests => 13;
use YAML ();
no warnings 'redefine';
use Module::Setup::Flavor::Default;

*Module::Setup::select_flavor = sub { 'default' };
dialog {
    my($self, $msg, $default) = @_;
    return $default if $msg =~ /Your svk base scratch/;
    return 'n'
};

module_setup { init => 1, plugins => ['VC::SVK'] };

do {
    local *Module::Setup::Flavor::Default::setup_config = sub {
        my($class, $context, $config) = @_;
        $config->{plugin_vc_svk_scratch_repos} = '//test';
    };
    module_setup { init => 1, plugins => ['VC::SVK'] }, 'svk2';
    is YAML::LoadFile(config_file('svk2'))->{plugin_vc_svk_scratch_repos}, '//test';
};

do {
    my $i = 0;
    local *Module::Setup::system = sub { $i++ };
    module_setup { target => 1 }, 'VC::SVK0';
    is $i, 0;
};

do {
    dialog {
        my($self, $msg, $default) = @_;
        return 1   if $msg =~ /Select flavor/;
        return 'y' if $msg =~ /SVK/;
        return 'y' if $msg =~ /Subversion friendly/;
        return 'n';
    };

    my @tests = (
        [qw/ svk import /],
        [qw/ svk co 1 /],
    );
    
    local *Module::Setup::system = sub {
        my($self, @args) = @_;
        my $test = shift @tests;
        is $args[0], $test->[0];
        is $args[1], $test->[1];
        if ($test->[2]) {
            like $args[-2], qr!/trunk$!;
        }
        return 0;
    };
    module_setup { target => 1 }, 'VC::SVK::SVN';
};

dialog {
    my($self, $msg, $default) = @_;
    $msg =~ /SVK/ ? 'y' : 'n';
};

do {
    my @tests = (
        [qw/ svk import /],
        [qw/ svk co /],
    );
    
    local *Module::Setup::system = sub {
        my($self, @args) = @_;
        my $test = shift @tests;
        is $args[0], $test->[0];
        is $args[1], $test->[1];
        return 0;
    };

    module_setup { target => 1 }, 'VC::SVK1';
};

do {
    local *Module::Setup::system = sub {
        return $? = 1;
    };
    eval { module_setup { target => 1 }, 'VC::SVK2' };
    like $@, qr/1 at /;
};

do {
    my $i = 0;
    local *Module::Setup::system = sub {
        return 0 unless $i++;
        return $? = 2;
    };
    eval { module_setup { target => 1 }, 'VC::SVK3' };
    like $@, qr/2 at /;
};
