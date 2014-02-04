use Module::Setup::Test::Utils;
use Test::More tests => 21;
use Config;

module_setup { init => 1 };
my $make = $Config{make};

dialog {
    my($self, $msg, $default) = @_;
    return 'n' if $msg =~ /Subversion/;
    return $default unless $msg =~ /Check Makefile.PL\?/;
    like $msg, qr/Check Makefile.PL\?/;
    is $default, 'y';
    'n';
};
module_setup { target => 1 }, 'Test::Makefile1';
ok !-f target_dir('Test-Makefile1')->file('MANIFEST');

dialog {
    my($self, $msg, $default) = @_;
    return 'n' if $msg =~ /Subversion/;
    $default;
};
{
    my @tests = (
        [qw/perl Makefile.PL/],
        [$make, 'test'],
        [$make, 'manifest'],
        [$make, 'distclean'],
    );
    no warnings 'redefine';
    local *Module::Setup::system = sub {
        my($self, @args) = @_;
        my $cmds = shift @tests;
        is_deeply $cmds, \@args;
        return 0;
    };
    module_setup { target => 1 }, 'Test::Makefile2';
}

{
    my @tests = (
        { cmds => [qw/perl Makefile.PL/], code => 1 },
        { cmds => [$make, 'test']       , code => 2 },
        { cmds => [$make, 'manifest']   , code => 3 },
        { cmds => [$make, 'distclean']  , code => 4 },
    );
    my @stack_test;
    my @pre_cmds;
    no warnings 'redefine';
    local *Module::Setup::system = sub {
        my($self, @args) = @_;
        if (@pre_cmds) {
            my $cmds = shift @pre_cmds;
            is_deeply $cmds, \@args;
            return 0;
        }
        my $cmds = shift @tests;
        is_deeply $cmds->{cmds}, \@args;
        push @stack_test, $cmds->{cmds};
        return $? = $cmds->{code};
    };
    for my $code (1..4) {
        local $@;
        @pre_cmds = @stack_test;
        eval { module_setup { target => 1 }, 'Test::Makefile3_' . $code };
        like $@, qr/$code at /;
    }
}
