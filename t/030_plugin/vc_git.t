use t::Utils;
use Test::More;

system 'git', '--version';
plan skip_all => "git is not installed." if $?;

plan tests => 26;

module_setup { init => 1 };

dialog {
    my($self, $msg, $default) = @_;
    'n';
};
module_setup { target => 1, plugins => ['VC::Git'] }, 'VC::Git0';
ok !-f target_dir('VC-Git')->file('.gitignore');
ok !-d target_dir('VC-Git', '.git');

dialog {
    my($self, $msg, $default) = @_;
    return 'n' unless $msg =~ /Git/;
    like $msg, qr/Git init\?/;
    is $default, 'y';
    'y';
};

{
    no warnings 'redefine';
    local *Module::Setup::system = sub {
        my($self, @args) = @_;
        my $cmd = join ' ', @args;
        `$cmd`;
        return 0;
    };
    module_setup { target => 1, plugins => ['VC::Git'] }, 'VC::Git';
}
ok -f target_dir('VC-Git')->file('.gitignore');
ok -d target_dir('VC-Git', '.git');

{
    my @tests = (
        [qw/git init/],
        [qw/git add .gitignore/],
        [qw/git commit -m/, 'initial commit'],
    );
    no warnings 'redefine';
    local *Module::Setup::system = sub {
        my($self, @args) = @_;
        return 0 if @tests == 1 && $args[1] ne 'commit';
        my $cmds = shift @tests;
        is_deeply $cmds, \@args;
        return 0;
    };
    module_setup { target => 1, plugins => ['VC::Git'] }, 'VC::Git2';
}

{
    my @tests = (
        { cmds => [qw/git init/]                       , code => 1 },
        { cmds => [qw/git add .gitignore/]             , code => 2 },
        { cmds => [qw/git commit -m/, 'initial commit'], code => 3 },
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
        return 0 if @tests == 1 && $args[1] ne 'commit';
        my $cmds = shift @tests;
        is_deeply $cmds->{cmds}, \@args;
        push @stack_test, $cmds->{cmds};
        return $? = $cmds->{code};
    };
    for my $code (1..3) {
        local $@;
        @pre_cmds = @stack_test;
        eval { module_setup { target => 1, plugins => ['VC::Git'] }, 'VC::Git3_' . $code };
        like $@, qr/$code at /;
    }
}
