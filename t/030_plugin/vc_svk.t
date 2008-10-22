use t::Utils;
use Test::More tests => 7;
no warnings 'redefine';

module_setup { init => 1, plugins => ['VC::SVK'] };

do {
    dialog { 'n' };

    my $i = 0;
    local *Module::Setup::system = sub { $i++ };
    module_setup { target => 1 }, 'VC::SVK0';
    is $i, 0;
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
